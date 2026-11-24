# PI4-244 — Roteiro sugerido de vídeo (12 min e 30 s)

**Duração permitida pela disciplina:** 10 a 15 minutos. **Cada integrante precisa falar pelo menos 1 min e 30 s**, informando nome completo no início de sua participação. Este exemplo foi dividido entre **quatro pessoas**, mas deve ser ajustado ao número real de integrantes. NÃO leia os arquivos SQL em voz alta: explique as decisões e mostre os resultados.

## Distribuição sugerida

| Tempo | Participante | Tema e tela |
|---|---|---|
| **0:00–2:30** | Integrante 1 | Problema do FolcStore, público, modelos conceitual/lógico, visão das 13 tabelas no DBeaver. |
| **2:30–5:10** | Integrante 2 | Especializações de usuários, tabelas associativas N:M, tipos PostgreSQL, PKs e FKs, políticas ON DELETE. |
| **5:10–8:00** | Integrante 3 | Regras `CHECK`, `UNIQUE`, `NOT NULL`, `DEFAULT`, status, dados fictícios, 101 registros, 17 produtos. |
| **8:00–12:30** | Integrante 4 | Execução limpa em banco demonstrativo: `ddl.sql`, `seed_dml.sql`, validações e dois erros nativos intencionais. |

**Total previsto: 12 min e 30 s.** Cada bloco permite mais de 1 min e 30 s de participação. Se houver mais ou menos pessoas, redistribuam a narração sem descumprir o tempo individual. Façam um ensaio cronometrado.

## Falas-guia (não é necessário ler literalmente)

### Integrante 1 — Contexto do problema

> Olá, meu nome é [NOME COMPLETO]. Nosso projeto é o FolcStore, um sistema de comercialização de artesanato. Queremos conectar artesãos e compradores, mantendo organizados os cadastros, produtos, carrinhos, pedidos e entregas. Um banco relacional reduz problemas como pedidos sem comprador, produtos ligados a artesãos inexistentes e dados incoerentes. Partimos do modelo conceitual e lógico do grupo e implementamos o modelo físico em PostgreSQL, com 13 tabelas. Nesta visualização do DBeaver, mostramos as áreas de usuários, produtos, compras e postagens.

Mostre o diagrama e destaque três grupos sem percorrer todas as colunas. Explique o caminho lógico: usuários → produtos → carrinho/pedido → entrega.

### Integrante 2 — Decisões técnicas do modelo

> Olá, meu nome é [NOME COMPLETO]. Na implementação, preservamos a entidade `usuarios` e suas especializações `compradores`, `artesaos` e `administradores`. Cada especialização utiliza o mesmo identificador do usuário como chave primária e estrangeira. Para carrinhos e pedidos, usamos tabelas associativas com chaves compostas, já que diferentes produtos podem aparecer em diferentes compras. Escolhemos `INTEGER` para IDs e `NUMERIC(12,2)` para valores monetários. Chaves estrangeiras protegem os relacionamentos. Em exclusões, usamos `RESTRICT` para preservar referências históricas e `CASCADE` apenas onde faz sentido, como nas imagens de produtos e itens de carrinho.

No DBeaver, destaque `usuarios`, `compradores`, `artesaos` e `itens_pedido`. Mostre uma FK nomeada e explique o motivo, sem ler os comandos SQL.

### Integrante 3 — Regras de negócio e povoamento

> Olá, meu nome é [NOME COMPLETO]. Adicionamos restrições para que as informações obedeçam às regras de negócio. Por exemplo, `CHECK` impede preços negativos, estoque negativo e valores não previstos para status. Nas avaliações, a nota vai de 1 a 5; nos itens do pedido, o subtotal deve corresponder à multiplicação do preço pela quantidade. Campos essenciais usam `NOT NULL`, e e-mails de usuários são únicos. O povoamento utiliza dados totalmente fictícios, com pelo menos três registros em todas as tabelas e 17 produtos artesanais. Validamos também as somas dos pedidos e as relações entre artesãos, postagens e avaliações na base de demonstração.

Mostre algumas constraints no DBeaver e a consulta com o catálogo de 17 produtos, relacionada aos quatro artesãos fictícios. Explique que algumas regras entre múltiplas tabelas são **verificadas por consultas** e não exclusivamente impostas por CHECK.

### Integrante 4 — Demonstração real, com banco limpo

> Olá, meu nome é [NOME COMPLETO]. Para demonstrar a criação do banco do início ao fim, utilizamos `folcstore_av2_demo`, um banco separado e inicialmente vazio, sem apagar o ambiente que já usamos no desenvolvimento. Primeiro mostramos que ele não tem tabelas. Depois executamos `ddl.sql`, que cria as 13 tabelas e índices. O script termina com COMMIT. Em seguida, executamos `seed_dml.sql` e verificamos os 101 registros. Finalmente, testamos duas entradas inválidas: um produto com preço negativo, bloqueado por CHECK, e uma postagem de um artesão inexistente, bloqueada por FOREIGN KEY. Repare que o PostgreSQL mostra os nomes das restrições responsáveis pelo bloqueio. Essas validações demonstram como a estrutura impede a entrada de dados inválidos.

**Comandos:** abra `README_PI4-244.md`, seção 5, e copie os comandos de 1 a 7. **Prepare o banco com `preparar_demo.ps1` antes de iniciar a gravação** (ele deixa o banco vazio e os SQLs copiados). Na gravação, mostre rapidamente as linhas importantes: ausência de tabelas, `CREATE TABLE`/`COMMIT`, `INSERT`/`COMMIT`, contagens e erros de `CHECK`/`FOREIGN KEY`.

## Checklist do ensaio

- [ ] Cada integrante diz nome completo, participa por no mínimo 1min30 e não lê código mecanicamente.
- [ ] A gravação tem entre 10min e 15min.
- [ ] O diagrama aparece legível e mostra os relacionamentos.
- [ ] Explicam o problema e por que o modelo relacional resolve riscos concretos.
- [ ] Explicam PK, FK, tipos, especializações, N:M, CHECK, UNIQUE e políticas de exclusão.
- [ ] A execução de `ddl.sql` e `seed_dml.sql` é mostrada em banco vazio.
- [ ] Dois erros nativos do PostgreSQL aparecem na tela, com a regra violada.
- [ ] Nenhuma senha ou informação pessoal aparece na gravação.
- [ ] Vídeo exportado e reproduzido integralmente antes do envio.
