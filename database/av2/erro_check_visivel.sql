-- PI4-244 | Falha INTENCIONAL para exibir o ERROR nativo do PostgreSQL.
-- Execute SOMENTE no banco de demonstracao ja povoado.
-- A insercao sera recusada pelo CHECK ck_produtos_preco: nenhum registro sera criado.
INSERT INTO produtos
    (titulo, descricao, tecnica, regiao_producao, categoria, preco, quantidade_estoque, id_artesao)
VALUES
    ('Teste invalido: preco negativo', 'Exemplo academico de CHECK', 'Ceramica',
     'Pernambuco', 'Decoracao', -10.00, 1, 201);
