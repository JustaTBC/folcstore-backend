

BEGIN;
SET LOCAL search_path TO public;

DO $guard$
DECLARE
    tabela TEXT;
    tem_dados BOOLEAN;
BEGIN
    FOREACH tabela IN ARRAY ARRAY[
        'usuarios', 'compradores', 'artesaos', 'administradores',
        'enderecos', 'produtos', 'imagens_produto', 'carrinhos',
        'itens_carrinho', 'pedidos', 'itens_pedido', 'postagens', 'avaliacoes'
    ] LOOP
        EXECUTE format('SELECT EXISTS(SELECT 1 FROM public.%I)', tabela) INTO tem_dados;
        IF tem_dados THEN
            RAISE EXCEPTION 'A tabela % ja contem dados: povoamento bloqueado sem alterar o banco.', tabela;
        END IF;
    END LOOP;
END
$guard$;

-- 1. Usuarios e especializacoes

INSERT INTO usuarios (id, nome, email, senha, telefone, ativo, data_cadastro) VALUES
    (101, 'Pessoa Fictícia Compradora 101', 'comprador01@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (102, 'Pessoa Fictícia Comprador 102', 'comprador02@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (103, 'Pessoa Fictícia Compradora 103', 'comprador03@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (104, 'Pessoa Fictícia Comprador 104', 'comprador04@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (201, 'Pessoa Fictícia Artesã 201', 'artesao01@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (202, 'Pessoa Fictícia Artesã 202', 'artesao02@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (203, 'Pessoa Fictícia Artesão 203', 'artesao03@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (204, 'Pessoa Fictícia Artesã 204', 'artesao04@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (301, 'Pessoa Fictícia Administração 301', 'admin01@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (302, 'Pessoa Fictícia Administração 302', 'admin02@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03'),
    (303, 'Pessoa Fictícia Administração 303', 'admin03@example.test', 'HASH_DEMO_NAO_UTILIZAR_EM_LOGIN', NULL, TRUE, '2026-09-01 09:00:00-03');

INSERT INTO compradores (id_usuario, cpf, data_nascimento) VALUES
    (101, NULL, NULL),
    (102, NULL, NULL),
    (103, NULL, NULL),
    (104, NULL, NULL);

INSERT INTO artesaos (id_usuario, nome_artesao, regiao_producao) VALUES
    (201, 'Ateliê Barro Inventado', 'Caruaru - PE'),
    (202, 'Oficina Trama Fictícia', 'Recife - PE'),
    (203, 'Tear do Horizonte Imaginário', 'Olinda - PE'),
    (204, 'Oficina Semente do Sertão', 'Sertão de Pernambuco');

INSERT INTO administradores (id_usuario, nivel_acesso) VALUES
    (301, 'OPERACIONAL'),
    (302, 'SUPERVISOR'),
    (303, 'GERAL');

-- 2. Enderecos ficticios de entrega

INSERT INTO enderecos (id, logradouro, numero, bairro, cidade, estado, cep, complemento) VALUES
    (601, 'Rua Fictícia das Artes', '10', 'Bairro Exemplo 1', 'Recife', 'PE', '50000000', 'Prédio de demonstração'),
    (602, 'Travessa Imaginária do Mercado', '25', 'Bairro Exemplo 2', 'Olinda', 'PE', '53000000', NULL),
    (603, 'Alameda de Demonstração', '30', 'Bairro Exemplo 3', 'Caruaru', 'PE', '55000000', 'Casa fictícia'),
    (604, 'Rua Cenário do Artesanato', '50', 'Bairro Exemplo 4', 'Recife', 'PE', '51000000', 'Destinação de teste compartilhada'),
    (605, 'Rua Exemplo do Sertão', '70', 'Bairro Exemplo 5', 'Petrolina', 'PE', '56000000', NULL),
    (606, 'Praça Fictícia das Cores', '15', 'Bairro Exemplo 6', 'Garanhuns', 'PE', '55200000', NULL);

-- 3. Produtos artesanais e imagens ficticias

INSERT INTO produtos (id, titulo, descricao, materia_prima, tecnica, regiao_producao, categoria, tipo, preco, quantidade_estoque, dimensoes, guia_cuidados, status, data_cadastro, id_artesao) VALUES
    (1001, 'Vaso de barro pintado', 'Vaso artesanal com pintura geométrica.', 'Argila', 'Modelagem manual', 'Caruaru - PE', 'Decoração', 'LOTE', 89.90, 8, '20 x 12 x 12 cm', 'Limpar com pano seco.', 'ATIVO', '2026-09-10 10:00:00-03', 201),
    (1002, 'Moringa de barro decorativa', 'Moringa cerâmica modelada manualmente.', 'Argila', 'Modelagem manual', 'Caruaru - PE', 'Decoração', 'LOTE', 149.90, 3, '30 x 15 x 15 cm', 'Evitar impacto.', 'ATIVO', '2026-09-10 10:00:00-03', 201),
    (1003, 'Escultura única de barro', 'Peça única vendida e atualmente sem estoque.', 'Argila', 'Escultura manual', 'Caruaru - PE', 'Escultura', 'UNICO', 249.00, 0, '25 x 15 x 15 cm', 'Não expor à umidade.', 'PAUSADO', '2026-09-10 10:00:00-03', 201),
    (1004, 'Prato decorativo de argila', 'Prato ornamental com acabamento artesanal.', 'Argila', 'Modelagem manual', 'Caruaru - PE', 'Decoração', 'LOTE', 68.50, 5, '25 x 25 x 3 cm', 'Uso decorativo apenas.', 'ATIVO', '2026-09-10 10:00:00-03', 201),
    (1005, 'Bolsa de palha trançada', 'Bolsa de mão feita com palha natural.', 'Palha', 'Trançado manual', 'Recife - PE', 'Acessórios', 'LOTE', 68.00, 12, '30 x 26 x 10 cm', 'Manter em local seco.', 'ATIVO', '2026-09-10 10:00:00-03', 202),
    (1006, 'Porta-copos de palha', 'Conjunto de porta-copos trançados à mão.', 'Palha', 'Trançado manual', 'Recife - PE', 'Casa', 'LOTE', 32.50, 20, '10 x 10 cm', 'Limpar com pano úmido.', 'ATIVO', '2026-09-10 10:00:00-03', 202),
    (1007, 'Cesto de palha artesanal', 'Cesto de armazenamento feito com fibras vegetais.', 'Palha', 'Trançado manual', 'Recife - PE', 'Casa', 'LOTE', 115.00, 7, '35 x 25 x 25 cm', 'Evitar molhar.', 'ATIVO', '2026-09-10 10:00:00-03', 202),
    (1008, 'Chapéu de palha tradicional', 'Chapéu com trama resistente e acabamento manual.', 'Palha', 'Trançado manual', 'Recife - PE', 'Acessórios', 'LOTE', 78.90, 5, 'Tamanho ajustável', 'Guardar protegido do sol.', 'ATIVO', '2026-09-10 10:00:00-03', 202),
    (1009, 'Tapete de tear manual', 'Tapete decorativo confeccionado em tear.', 'Algodão', 'Tecelagem manual', 'Olinda - PE', 'Casa', 'LOTE', 129.00, 4, '100 x 60 cm', 'Lavar à mão.', 'ATIVO', '2026-09-10 10:00:00-03', 203),
    (1010, 'Manta de algodão tecida', 'Manta de algodão com textura artesanal.', 'Algodão', 'Tecelagem manual', 'Olinda - PE', 'Casa', 'LOTE', 185.00, 6, '150 x 120 cm', 'Secar à sombra.', 'ATIVO', '2026-09-10 10:00:00-03', 203),
    (1011, 'Jogo americano tecido', 'Lugar americano feito em tear de algodão.', 'Algodão', 'Tecelagem manual', 'Olinda - PE', 'Casa', 'LOTE', 59.00, 12, '40 x 30 cm', 'Lavar delicadamente.', 'ATIVO', '2026-09-10 10:00:00-03', 203),
    (1012, 'Almofada tecida artesanal', 'Almofada decorativa em algodão tecido.', 'Algodão', 'Tecelagem manual', 'Olinda - PE', 'Decoração', 'LOTE', 59.00, 9, '40 x 40 cm', 'Lavar capa à mão.', 'ATIVO', '2026-09-10 10:00:00-03', 203),
    (1013, 'Colar de sementes', 'Colar ornamental feito com sementes secas.', 'Sementes', 'Montagem artesanal', 'Serra Talhada - PE', 'Acessórios', 'LOTE', 45.00, 8, '45 cm', 'Guardar longe da umidade.', 'ATIVO', '2026-09-10 10:00:00-03', 204),
    (1014, 'Brincos de madeira entalhada', 'Par de brincos de madeira com acabamento manual.', 'Madeira', 'Entalhe manual', 'Serra Talhada - PE', 'Acessórios', 'LOTE', 55.00, 9, '5 x 2 cm', 'Limpar com flanela.', 'ATIVO', '2026-09-10 10:00:00-03', 204),
    (1015, 'Matriz de xilogravura', 'Matriz artesanal de madeira indisponível.', 'Madeira', 'Xilogravura', 'Serra Talhada - PE', 'Arte', 'UNICO', 85.00, 0, '15 x 10 cm', 'Não molhar.', 'INATIVO', '2026-09-10 10:00:00-03', 204),
    (1016, 'Luminária de fibra vegetal', 'Peça em preparação editorial, ainda não publicada.', 'Fibra vegetal', 'Trançado manual', 'Serra Talhada - PE', 'Decoração', 'LOTE', 210.00, 2, '35 x 18 cm', 'Uso interno apenas.', 'RASCUNHO', '2026-09-10 10:00:00-03', 204),
    (1017, 'Ganzá de cabaça pirogravada', 'Instrumento de percussão singular para testar recomendação sem pares da mesma técnica, material e categoria.', 'Cabaça', 'Pirogravura', 'Petrolina - PE', 'Instrumentos Musicais', 'UNICO', 380.00, 1, '28 x 9 cm', 'Guardar em local seco.', 'ATIVO', '2026-09-10 10:00:00-03', 204);

INSERT INTO imagens_produto (id, url_imagem, id_produto) VALUES
    (1101, 'https://example.test/folcstore/produtos/1001.jpg', 1001),
    (1102, 'https://example.test/folcstore/produtos/1002.jpg', 1002),
    (1103, 'https://example.test/folcstore/produtos/1003.jpg', 1003),
    (1104, 'https://example.test/folcstore/produtos/1004.jpg', 1004),
    (1105, 'https://example.test/folcstore/produtos/1005.jpg', 1005),
    (1106, 'https://example.test/folcstore/produtos/1006.jpg', 1006),
    (1107, 'https://example.test/folcstore/produtos/1007.jpg', 1007),
    (1108, 'https://example.test/folcstore/produtos/1008.jpg', 1008),
    (1109, 'https://example.test/folcstore/produtos/1009.jpg', 1009),
    (1110, 'https://example.test/folcstore/produtos/1010.jpg', 1010),
    (1111, 'https://example.test/folcstore/produtos/1011.jpg', 1011),
    (1112, 'https://example.test/folcstore/produtos/1012.jpg', 1012),
    (1113, 'https://example.test/folcstore/produtos/1013.jpg', 1013),
    (1114, 'https://example.test/folcstore/produtos/1014.jpg', 1014),
    (1115, 'https://example.test/folcstore/produtos/1015.jpg', 1015),
    (1116, 'https://example.test/folcstore/produtos/1016.jpg', 1016),
    (1117, 'https://example.test/folcstore/produtos/1017.jpg', 1017);

-- 4. Carrinhos e itens

INSERT INTO carrinhos (id, data_criacao, id_comprador) VALUES
    (1201, '2026-11-05 10:00:00-03', 101),
    (1202, '2026-11-05 11:00:00-03', 102),
    (1203, '2026-11-06 09:00:00-03', 103);

INSERT INTO itens_carrinho (id_carrinho, id_produto, quantidade, preco_unitario) VALUES
    (1201, 1002, 1, 149.90),
    (1201, 1008, 2, 78.90),
    (1202, 1011, 1, 59.00),
    (1202, 1013, 2, 45.00),
    (1203, 1004, 1, 68.50),
    (1203, 1014, 1, 55.00);

-- 5. Pedidos e itens de pedido

INSERT INTO pedidos (id, data_pedido, status, valor_total, id_comprador, id_endereco) VALUES
    (1301, '2026-09-15 10:00:00-03', 'ENTREGUE', 216.90, 101, 601),
    (1302, '2026-10-05 10:00:00-03', 'ENVIADO', 184.00, 102, 602),
    (1303, '2026-10-22 10:00:00-03', 'CONFIRMADO', 149.90, 103, 603),
    (1304, '2026-11-01 10:00:00-03', 'EM_PREPARACAO', 65.00, 101, 604),
    (1305, '2026-11-07 10:00:00-03', 'PENDENTE', 115.00, 102, 605),
    (1306, '2026-11-10 10:00:00-03', 'CANCELADO', 45.00, 103, 606),
    (1307, '2026-09-29 10:00:00-03', 'ENTREGUE', 434.00, 103, 604);

INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario, subtotal) VALUES
    (1301, 1001, 1, 89.90, 89.90),
    (1301, 1005, 1, 68.00, 68.00),
    (1301, 1012, 1, 59.00, 59.00),
    (1302, 1009, 1, 129.00, 129.00),
    (1302, 1014, 1, 55.00, 55.00),
    (1303, 1002, 1, 149.90, 149.90),
    (1304, 1006, 2, 32.50, 65.00),
    (1305, 1007, 1, 115.00, 115.00),
    (1306, 1013, 1, 45.00, 45.00),
    (1307, 1003, 1, 249.00, 249.00),
    (1307, 1010, 1, 185.00, 185.00);

-- 6. Postagens e avaliacoes ficticias

INSERT INTO postagens (id, data_postagem, transportadora, codigo_rastreio, id_pedido, id_artesao) VALUES
    (1401, '2026-09-18 14:00:00-03', 'Transportadora Exemplo A', 'DEMO-1301-201', 1301, 201),
    (1402, '2026-09-18 14:00:00-03', 'Transportadora Exemplo B', 'DEMO-1301-202', 1301, 202),
    (1403, '2026-09-18 14:00:00-03', 'Transportadora Exemplo C', 'DEMO-1301-203', 1301, 203),
    (1404, '2026-10-07 14:00:00-03', 'Transportadora Exemplo C', 'DEMO-1302-203', 1302, 203),
    (1405, '2026-10-07 14:00:00-03', 'Transportadora Exemplo D', 'DEMO-1302-204', 1302, 204),
    (1406, '2026-10-02 14:00:00-03', 'Transportadora Exemplo A', 'DEMO-1307-201', 1307, 201),
    (1407, '2026-10-02 14:00:00-03', 'Transportadora Exemplo C', 'DEMO-1307-203', 1307, 203);

INSERT INTO avaliacoes (id, nota, comentario, data, id_comprador, id_produto) VALUES
    (1501, 5, 'Bom acabamento para uma peça artesanal fictícia.', '2026-09-25 09:00:00-03', 101, 1001),
    (1502, 4, 'A bolsa de demonstração ficou adequada ao pedido.', '2026-09-25 09:30:00-03', 101, 1005),
    (1503, 5, 'Peça decorativa com ótima textura.', '2026-09-25 10:00:00-03', 101, 1012),
    (1504, 5, 'Escultura singular de ótima qualidade.', '2026-10-08 11:00:00-03', 103, 1003),
    (1505, 4, 'Manta fictícia bem acabada.', '2026-10-08 11:30:00-03', 103, 1010);

-- Como o seed utiliza IDs explicitos, ajustar as sequencias IDENTITY.
-- Isso permite inserir novas linhas sem choque com os IDs ficticios.
SELECT setval(pg_get_serial_sequence('public.usuarios', 'id'), (SELECT MAX(id) FROM public.usuarios), true);
SELECT setval(pg_get_serial_sequence('public.enderecos', 'id'), (SELECT MAX(id) FROM public.enderecos), true);
SELECT setval(pg_get_serial_sequence('public.produtos', 'id'), (SELECT MAX(id) FROM public.produtos), true);
SELECT setval(pg_get_serial_sequence('public.imagens_produto', 'id'), (SELECT MAX(id) FROM public.imagens_produto), true);
SELECT setval(pg_get_serial_sequence('public.carrinhos', 'id'), (SELECT MAX(id) FROM public.carrinhos), true);
SELECT setval(pg_get_serial_sequence('public.pedidos', 'id'), (SELECT MAX(id) FROM public.pedidos), true);
SELECT setval(pg_get_serial_sequence('public.postagens', 'id'), (SELECT MAX(id) FROM public.postagens), true);
SELECT setval(pg_get_serial_sequence('public.avaliacoes', 'id'), (SELECT MAX(id) FROM public.avaliacoes), true);

COMMIT;
-- No psql, o resultado final esperado e COMMIT. Depois rode verificar_povoamento.sql.
