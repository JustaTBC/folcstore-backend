# Recomendações em produção (PI4-192)

O serviço Python usa os produtos ativos e com estoque enviados pelo Express. O cálculo considera técnica, região e similaridade da descrição. A API pública GET /api/recomendacoes recebe produtoId, limite e modo, consulta o serviço Python e devolve IDs que pertencem ao catálogo.

## Serviço Python no Render

Crie um Web Service no plano Free, a partir do repositório pedrofalcaos/folcstore-backend, branch main, na mesma região da API Express.

| Configuração | Valor |
| --- | --- |
| Runtime | Python 3 |
| Root Directory | services/recomendador |
| Build Command | python --version |
| Start Command | python server.py --host 0.0.0.0 --workers 2 |
| Health Check | /health |

O Render fornece PORT. O serviço usa apenas a biblioteca padrão, sem dependências de pip.

No serviço Express, configure RECOMMENDER_URL para a URL do Python, sem barra final, e reinicie a API. Para testar, consulte /api/recomendacoes?produtoId=ID_REAL. Com apenas um produto, a resposta de sucesso contém uma lista vazia de sugestões.

## Área do cliente

A área /customer busca o histórico do usuário e escolhe como origem um produto comprado ainda disponível. Se não houver, usa um produto disponível do catálogo. Em seguida consulta a API de recomendações e exibe os produtos sugeridos, excluindo produtos já comprados ou indisponíveis.

Se o serviço estiver indisponível, mantém o fallback local por categoria e histórico. Serviços gratuitos podem suspender por inatividade. A primeira consulta após a suspensão pode usar esse fallback até o Python iniciar.

## Validação

Os testes do backend usam o processo Python real e verificam os modos sequencial e paralelo, IDs do banco, corpo inválido e indisponibilidade. O teste de navegador valida a chamada da área do cliente à API e o fallback quando ela responde 503.

Para mostrar sugestões em produção, cadastre pelo menos dois produtos ativos com estoque. Nenhuma credencial de banco é necessária no serviço Python.
