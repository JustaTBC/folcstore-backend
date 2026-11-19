# Cache Redis do catálogo (PI4-198)

## Funcionamento

O GET /api/produtos guarda no Redis a resposta JSON por até 60 segundos. Cada combinação de busca, filtros, página e limite tem uma chave própria. O corpo JSON permanece igual ao da consulta direta.

Antes de ler o cache, a API consulta a versão do catálogo no banco. Criar, editar, excluir um produto ou confirmar uma compra incrementa essa versão na mesma transação da alteração. As próximas consultas usam uma nova chave. Uma consulta que terminou atrasada só consegue preencher a versão antiga, que expira pelo TTL.

Os detalhes, o carrinho e o checkout consultam diretamente o banco. O Redis é opcional. Sem configuração, ou quando a conexão falha, a API consulta o banco. A versão continua sendo atualizada durante falhas do Redis, inclusive com várias instâncias da API.

O cache reduz as consultas completas de listagem e contagem. Cada acerto ainda consulta uma linha pequena de versão no banco. Isso garante a invalidação mesmo se o Redis estava indisponível no momento da alteração.

O header X-Cache-Catalogo indica a origem da resposta: BANCO na consulta direta e REDIS no acerto de cache. No navegador, abra Network e confira os headers de /api/produtos.

## Teste local no PowerShell

Com Docker Desktop rodando, crie uma instância local dedicada:

```powershell
docker run -d --name folcstore-redis-pi4-198 -p 127.0.0.1:6380:6379 redis:7-alpine
```

Se o contêiner já existe, use `docker start folcstore-redis-pi4-198`.

Na pasta do backend, execute:

```powershell
npm run db:generate
npm run db:migrate
$env:TEST_REDIS_URL = "redis://127.0.0.1:6380"
npm run test:cache
```

Os testes usam um banco temporário e chaves próprias. Verificam acertos de cache, separação de filtros/páginas, expiração configurada, criação, edição, exclusão, estoque após checkout, idempotência e uma leitura concorrente com edição.

Para testar a aplicação manualmente, configure `REDIS_URL=redis://127.0.0.1:6380` no .env e inicie com `npm run dev`. Abra /api/produtos duas vezes. `docker exec folcstore-redis-pi4-198 redis-cli INFO stats` mostra as contagens de acertos e falhas. Pare esse contêiner com `docker stop folcstore-redis-pi4-198` e abra a listagem novamente para verificar o fallback.

## Render

Depois de testar e integrar a alteração na main, o start:render aplica a migração PostgreSQL. Configure uma URL Redis com TLS na variável privada REDIS_URL do serviço Render. CACHE_CATALOGO_TTL_SEGUNDOS é opcional e aceita de 1 a 300, com padrão 60.

Uma instância Redis gratuita ainda precisa ser conectada para ativar o cache em produção. A senha faz parte da URL e deve ficar nas variáveis privadas do Render.

Mudanças manuais de produtos no banco devem incrementar VersaoCatalogo na mesma transação, como fazem as rotas da API.
