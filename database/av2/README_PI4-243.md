# PI4-243 — Popular e validar o banco de dados FolcStore

**Escopo:** povoamento e testes do modelo físico PostgreSQL criado na PI4-242. Este pacote **não modifica o `ddl.sql`, o Prisma, as rotas nem o backend**. O povoamento é feito **diretamente por SQL**, como exige a AV2 da disciplina de Banco de Dados.

## 1. Requisitos

- PostgreSQL 17 iniciado no Docker conforme PI4-241.
- As **13 tabelas** já criadas por `database/av2/ddl.sql` conforme PI4-242.
- Banco acadêmico **sem dados nas 13 tabelas**. O seed **não sobrescreve**, **não trunca** nem **apaga** dados; ele **interrompe** a execução se detectar qualquer tabela já povoada.
- Terminal na raiz do fork `folcstore-backend`, com `compose.postgres.yaml` e `.env.postgres` previamente configurados.
- **Não executar `ddl.sql` de novo**: ele já foi aplicado. Não usar comandos como `docker compose down -v` para tentar reiniciar o banco: eles podem apagar o volume com dados.

## 2. Dados fictícios incluídos

| Tabela | Quantidade |
|---|---:|
| `usuarios` | 11 |
| `compradores` | 4 |
| `artesaos` | 4 |
| `administradores` | 3 |
| `enderecos` | 6 |
| `produtos` | **17** |
| `imagens_produto` | 17 |
| `carrinhos` | 3 |
| `itens_carrinho` | 6 |
| `pedidos` | 7 |
| `itens_pedido` | 11 |
| `postagens` | 7 |
| `avaliacoes` | 5 |

Os usuários, endereços, comentários, e-mails e imagens são fictícios. Os e-mails e URLs usam `example.test` (domínio reservado para testes); os CPFs e telefones estão `NULL`. Os valores `HASH_DEMO_NAO_UTILIZAR_EM_LOGIN` **não são hashes válidos para autenticação**: servem apenas para preencher a coluna obrigatória `senha` nesta demonstração acadêmica. **Não utilize essas contas para login nem em produção.**

**Casos úteis para a IA:** `produtos.id=1017` é o único produto ativo da categoria `Instrumentos Musicais`, com matéria-prima e técnica únicas no catálogo; `compradores.id_usuario=104` existe sem carrinho, pedido ou avaliação. Há ainda itens pausados, inativos e em rascunho, para testar o filtro de elegibilidade.

## 3. Instalar os arquivos no fork

Copie os arquivos desta pasta para `database/av2/` do seu fork, **mantendo** o `ddl.sql`, `verificar_modelo.sql` e `testes_integridade.sql` criados na PI4-242:

```text
folcstore-backend/
  database/
    av2/
      ddl.sql                     # PI4-242: manter como está
      verificar_modelo.sql        # PI4-242
      testes_integridade.sql      # PI4-242
      seed_dml.sql                # PI4-243: novo
      verificar_povoamento.sql    # PI4-243: novo
      testes_povoamento.sql       # PI4-243: novo
      README_PI4-243.md           # PI4-243: novo
```

## 4. Executar no PowerShell

Verifique se o banco está ligado:

```powershell
# Somente se o PowerShell ainda não encontrar o comando docker:
$env:Path += ";C:\Program Files\Docker\Docker\resources\bin"

docker compose --env-file .env.postgres -f compose.postgres.yaml ps
```

**Atenção: o próximo comando insere dados no banco** `folcstore`. Só execute no contêiner **de desenvolvimento** da PI4-241 e se as 13 tabelas estiverem **vazias**.

```powershell
# Copiar o seed para dentro do contêiner
docker compose --env-file .env.postgres -f compose.postgres.yaml cp database/av2/seed_dml.sql postgres:/tmp/seed_dml.sql

# Executar o SQL; deve terminar com COMMIT
docker compose --env-file .env.postgres -f compose.postgres.yaml exec -T postgres psql -U folcstore -d folcstore -v ON_ERROR_STOP=1 -f /tmp/seed_dml.sql
```

Os registros são inseridos em uma transação (`BEGIN`/`COMMIT`): se houver erro, as inserções da transação não são confirmadas. **Não rode o seed uma segunda vez**, pois o bloqueio inicial recusará o povoamento sobre tabelas com dados. O SQL ajusta as sequências `IDENTITY` depois de inserir IDs explícitos, para não colidir com futuras inserções.

Se o usuário ou nome do banco foram alterados na configuração do Docker, ajuste `-U folcstore` e `-d folcstore`.

## 5. Validar os dados

```powershell
docker compose --env-file .env.postgres -f compose.postgres.yaml cp database/av2/verificar_povoamento.sql postgres:/tmp/verificar_povoamento.sql

docker compose --env-file .env.postgres -f compose.postgres.yaml exec -T postgres psql -U folcstore -d folcstore -v ON_ERROR_STOP=1 -f /tmp/verificar_povoamento.sql
```

**Resultados esperados:** contagens das 13 tabelas acima e mensagens `NOTICE: OK` confirmando:

- Pelo menos 3 registros por tabela e pelo menos 10 produtos.
- `pedidos.valor_total` igual à soma de `itens_pedido.subtotal`.
- Preços dos itens do carrinho iguais aos preços do catálogo de demonstração.
- Postagens de artesãos que participam dos pedidos enviados/entregues.
- Avaliações apenas de produtos adquiridos em pedidos entregues.
- Seis status de pedido representados.
- Casos especiais de IA (`104` sem histórico e `1017` sem par na categoria).

**Testes de falha intencional (sem alterar os dados):**

```powershell
docker compose --env-file .env.postgres -f compose.postgres.yaml cp database/av2/testes_povoamento.sql postgres:/tmp/testes_povoamento.sql

docker compose --env-file .env.postgres -f compose.postgres.yaml exec -T postgres psql -U folcstore -d folcstore -v ON_ERROR_STOP=1 -f /tmp/testes_povoamento.sql
```

Esperam-se **três `NOTICE: OK`**: preço negativo bloqueado, subtotal incorreto bloqueado, chave estrangeira inválida bloqueada. O teste termina com `ROLLBACK`, preservando o povoamento.

Para ver alguns produtos diretamente no terminal:

```powershell
docker compose --env-file .env.postgres -f compose.postgres.yaml exec -T postgres psql -U folcstore -d folcstore -c "SELECT id, titulo, categoria, preco, status FROM produtos ORDER BY id;"
```

No DBeaver, atualize a visualização do schema e abra `public → Tables → produtos → Data`.

## 6. Observações e limites

- O seed atende ao requisito acadêmico de pelo menos 3 registros por tabela e ao requisito de IA de 10 produtos. **Não implementa ainda a integração com o recomendador Python** nem o histórico de interações separado: isso será tratado nas histórias de IA, depois da compatibilização do Prisma com o novo modelo.
- O SQL foi elaborado para o **DDL efetivamente entregue na PI4-242**. O schema Prisma legado ainda usa UUID, centavos e perfis simplificados; **não rode migrations ou `db push` do schema antigo neste banco**.
- As checagens de totais de pedidos, coerência entre postagens e artesãos e legitimidade de avaliações são demonstradas pelo `verificar_povoamento.sql`. Parte dessas invariantes **não é imposta pelo DDL através de CHECK** e deverá ser garantida na camada de serviço ou em evoluções futuras.
- Endereços são destinos de pedidos e podem ser reutilizados, sem supor que pertençam a um comprador específico. Os exemplos usam endereços inventados e CEPs de demonstração.
- Como as datas são fixas, reexecutar os relatórios no futuro reproduz a mesma massa histórica; não são registros reais.

## 7. Versionar no Git

O commit desta história pode incluir somente os novos arquivos:

```powershell
git add database/av2/seed_dml.sql database/av2/verificar_povoamento.sql database/av2/testes_povoamento.sql database/av2/README_PI4-243.md
git status
git commit -m "feat(database): popula e valida banco PostgreSQL (PI4-243)"
git push origin HEAD
```

O `.env.postgres` deve permanecer ignorado no Git. **Anexe ao Jira o `seed_dml.sql` e a saída dos testes executados**, sem credenciais. Para a apresentação da AV2, execute o DDL e seed a partir de um **novo banco de demonstração vazio** e mostre as duas falhas intencionais exigidas no PDF.

## 8. Critérios de aceite

- [x] Seed SQL escrito com dados fictícios nas 13 tabelas.
- [x] Pelo menos 3 registros por tabela, 17 produtos e casos especiais para IA planejados e conferidos no gerador.
- [x] Script de verificação de contagem e consistência preparado.
- [x] Três testes intencionais de integridade preparados.
- [ ] Executar o seed e os testes **no PostgreSQL da equipe** e conferir as saídas antes de marcar a história como concluída.
