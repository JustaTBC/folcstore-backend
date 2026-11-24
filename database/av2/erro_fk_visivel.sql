-- PI4-244 | Falha INTENCIONAL para exibir o ERROR nativo do PostgreSQL.
-- Execute SOMENTE no banco de demonstracao ja povoado.
-- O artesao 999999 nao existe: a insercao sera recusada por FOREIGN KEY.
INSERT INTO postagens
    (transportadora, codigo_rastreio, id_pedido, id_artesao)
VALUES
    ('Transportadora de Teste', 'RASTREIO-INVALIDO', 1301, 999999);
