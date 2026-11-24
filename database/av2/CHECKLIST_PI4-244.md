# PI4-244 — Checklist de entrega da AV2 de Banco de Dados

**Prazo informado nas orientações:** 07/12/2026.

## Antes da gravação

- [ ] `ddl.sql` e `seed_dml.sql` estão versionados no fork, na pasta `database/av2/`.
- [ ] O diagrama físico e os dois modelos de referência estão disponíveis para consulta.
- [ ] PostgreSQL 17 no Docker está acessível; não serão usadas credenciais reais em vídeo.
- [ ] O banco principal `folcstore` com os 101 registros foi preservado.
- [ ] O banco separado `folcstore_av2_demo` foi criado vazio por `preparar_demo.ps1`.
- [ ] Scripts estão copiados para o contêiner (`/tmp/pi4244_*.sql`).
- [ ] O grupo ensaiou e distribuiu falas de >=1min30 para cada pessoa.

## Durante a gravação

- [ ] Vídeo entre 10 e 15 minutos.
- [ ] Cada pessoa anuncia o próprio nome completo no início da sua fala.
- [ ] Contextualização do problema do FolcStore, usuários e riscos da falta de integridade.
- [ ] Explicação de 13 tabelas, especializações, chaves compostas, tipos e ON DELETE.
- [ ] Justificativa dos CHECKs, NOT NULL, UNIQUE e DEFAULT, sem leitura literal de código.
- [ ] Banco de demonstração inicialmente vazio mostrado com `\dt`.
- [ ] `ddl.sql` executado sem erros, mostrando `COMMIT`.
- [ ] `seed_dml.sql` executado sem erros, mostrando `COMMIT`.
- [ ] Verificação das 13 tabelas e seus registros executada.
- [ ] Erro nativo de CHECK para preço negativo mostrado e explicado.
- [ ] Erro nativo de FK para artesão inexistente mostrado e explicado.

## Entrega e publicação

- [ ] Verificar se o vídeo está completo, legível e com áudio claro.
- [ ] Publicar como **YouTube Não listado** ou no Google Drive com acesso para `rdat@cesar.school` conforme o PDF.
- [ ] Entregar `ddl.sql` e `seed_dml.sql` **como arquivos de SQL**, além do link do vídeo.
- [ ] Colocar link do vídeo no campo da plataforma da disciplina e checar acesso antes do prazo.
- [ ] Marcar PI4-244 como concluída **após a gravação e o envio**.

## Evidência para o Jira

> A documentação final do modelo físico PostgreSQL foi organizada, contemplando as 13 tabelas, a justificativa das escolhas técnicas, os procedimentos de execução e os testes de integridade. Foi preparado um roteiro de apresentação com demonstração em banco isolado, preservando o banco de desenvolvimento já povoado. A etapa de gravação e submissão do vídeo será concluída pela equipe conforme as orientações da disciplina.

## Commit recomendado

```powershell
git add database/av2/
git status
git commit -m "docs(database): prepara documentacao e apresentacao da AV2 (PI4-244)"
git push origin HEAD
```

`.env.postgres` permanece ignorado pelo Git. Não adicionar tokens, senhas, banco `.db` nem volumes Docker.
