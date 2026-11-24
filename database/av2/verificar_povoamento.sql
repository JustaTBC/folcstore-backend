-- PI4-243 | Conferencia dos dados e consistencia do seed.
-- Leitura apenas: NAO insere, altera ou apaga registros.
-- Execute DEPOIS de seed_dml.sql no banco PostgreSQL academico.

-- 1. Contagem de registros por tabela, para mostrar ao professor.
SELECT tabela, quantidade
FROM (
    SELECT 'usuarios' AS tabela, COUNT(*) AS quantidade FROM usuarios
    UNION ALL SELECT 'compradores', COUNT(*) FROM compradores
    UNION ALL SELECT 'artesaos', COUNT(*) FROM artesaos
    UNION ALL SELECT 'administradores', COUNT(*) FROM administradores
    UNION ALL SELECT 'enderecos', COUNT(*) FROM enderecos
    UNION ALL SELECT 'produtos', COUNT(*) FROM produtos
    UNION ALL SELECT 'imagens_produto', COUNT(*) FROM imagens_produto
    UNION ALL SELECT 'carrinhos', COUNT(*) FROM carrinhos
    UNION ALL SELECT 'itens_carrinho', COUNT(*) FROM itens_carrinho
    UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
    UNION ALL SELECT 'itens_pedido', COUNT(*) FROM itens_pedido
    UNION ALL SELECT 'postagens', COUNT(*) FROM postagens
    UNION ALL SELECT 'avaliacoes', COUNT(*) FROM avaliacoes
) AS dados
ORDER BY tabela;

-- 2. Verificacoes automaticas (erro explicito se algo estiver inconsistente).
DO $validacao$
DECLARE
    tabela TEXT;
    qtd BIGINT;
    divergencias BIGINT;
    quantidade_status BIGINT;
BEGIN
    FOREACH tabela IN ARRAY ARRAY[
        'usuarios', 'compradores', 'artesaos', 'administradores',
        'enderecos', 'produtos', 'imagens_produto', 'carrinhos',
        'itens_carrinho', 'pedidos', 'itens_pedido', 'postagens', 'avaliacoes'
    ] LOOP
        EXECUTE format('SELECT COUNT(*) FROM public.%I', tabela) INTO qtd;
        IF qtd < 3 THEN
            RAISE EXCEPTION 'Tabela % possui apenas % registros; minimo esperado: 3.', tabela, qtd;
        END IF;
    END LOOP;
    RAISE NOTICE 'OK: todas as 13 tabelas contem pelo menos 3 registros.';

    SELECT COUNT(*) INTO qtd FROM produtos;
    IF qtd < 10 THEN
        RAISE EXCEPTION 'IA: catalogo insuficiente (% produtos, minimo 10).', qtd;
    END IF;
    RAISE NOTICE 'OK: catalogo possui % produtos (minimo 10 para a AV2 de IA).', qtd;

    SELECT COUNT(*) INTO divergencias
    FROM pedidos p
    WHERE p.valor_total <> COALESCE((
        SELECT SUM(ip.subtotal) FROM itens_pedido ip WHERE ip.id_pedido = p.id
    ), 0);
    IF divergencias <> 0 THEN
        RAISE EXCEPTION 'Existem % pedidos com total diferente da soma dos itens.', divergencias;
    END IF;
    RAISE NOTICE 'OK: valor_total de todos os pedidos corresponde a soma dos itens.';

    SELECT COUNT(*) INTO divergencias
    FROM itens_carrinho ic
    JOIN produtos pr ON pr.id = ic.id_produto
    WHERE ic.preco_unitario <> pr.preco;
    IF divergencias <> 0 THEN
        RAISE EXCEPTION 'Existem % itens de carrinho com preco divergente do catalogo.', divergencias;
    END IF;
    RAISE NOTICE 'OK: precos de carrinho correspondem aos do catalogo demonstrativo.';

    SELECT COUNT(*) INTO divergencias
    FROM postagens po
    WHERE NOT EXISTS (
        SELECT 1
        FROM itens_pedido ip
        JOIN produtos pr ON pr.id = ip.id_produto
        WHERE ip.id_pedido = po.id_pedido AND pr.id_artesao = po.id_artesao
    );
    IF divergencias <> 0 THEN
        RAISE EXCEPTION 'Existem % postagens cujo artesao nao participa do pedido.', divergencias;
    END IF;
    RAISE NOTICE 'OK: postagens ligadas a artesaos com produtos nos respectivos pedidos.';

    SELECT COUNT(*) INTO divergencias
    FROM pedidos p
    JOIN itens_pedido ip ON ip.id_pedido = p.id
    JOIN produtos pr ON pr.id = ip.id_produto
    WHERE p.status IN ('ENVIADO', 'ENTREGUE')
      AND NOT EXISTS (
          SELECT 1 FROM postagens po
          WHERE po.id_pedido = p.id AND po.id_artesao = pr.id_artesao
      );
    IF divergencias <> 0 THEN
        RAISE EXCEPTION 'Existem % itens de pedidos enviados/entregues sem postagem do artesao.', divergencias;
    END IF;
    RAISE NOTICE 'OK: pedidos enviados/entregues possuem postagens dos artesaos envolvidos.';

    SELECT COUNT(*) INTO divergencias
    FROM avaliacoes a
    WHERE NOT EXISTS (
        SELECT 1
        FROM pedidos p
        JOIN itens_pedido ip ON ip.id_pedido = p.id
        WHERE p.id_comprador = a.id_comprador
          AND ip.id_produto = a.id_produto
          AND p.status = 'ENTREGUE'
    );
    IF divergencias <> 0 THEN
        RAISE EXCEPTION 'Existem % avaliacoes sem compra entregue correspondente.', divergencias;
    END IF;
    RAISE NOTICE 'OK: avaliacoes referem-se a produtos comprados em pedidos entregues.';

    SELECT COUNT(DISTINCT status) INTO quantidade_status FROM pedidos;
    IF quantidade_status <> 6 THEN
        RAISE EXCEPTION 'Esperados 6 status de pedido demonstrados, encontrados %.', quantidade_status;
    END IF;
    RAISE NOTICE 'OK: os 6 status permitidos de pedido aparecem na base.';

    IF NOT EXISTS (SELECT 1 FROM compradores WHERE id_usuario = 104)
       OR EXISTS (SELECT 1 FROM carrinhos WHERE id_comprador = 104)
       OR EXISTS (SELECT 1 FROM pedidos WHERE id_comprador = 104)
       OR EXISTS (SELECT 1 FROM avaliacoes WHERE id_comprador = 104) THEN
        RAISE EXCEPTION 'IA: comprador ficticio 104 deveria existir sem historico.';
    END IF;
    RAISE NOTICE 'OK IA: comprador 104 existe sem historico de compras, carrinhos ou avaliacoes.';

    IF NOT EXISTS (SELECT 1 FROM produtos WHERE id = 1017 AND status = 'ATIVO')
       OR EXISTS (
           SELECT 1
           FROM produtos pr
           JOIN produtos referencia ON referencia.id = 1017
           WHERE pr.id <> referencia.id
             AND pr.status = 'ATIVO'
             AND pr.categoria = referencia.categoria
       ) THEN
        RAISE EXCEPTION 'IA: o produto 1017 deveria ser o unico ativo de sua categoria.';
    END IF;
    RAISE NOTICE 'OK IA: produto 1017 e o unico ativo de sua categoria.';
END
$validacao$;

-- 3. Resultados resumidos, uteis para a demonstracao.
SELECT status, COUNT(*) AS pedidos FROM pedidos GROUP BY status ORDER BY status;

SELECT categoria, COUNT(*) AS produtos_ativos_com_estoque
FROM produtos
WHERE status = 'ATIVO' AND quantidade_estoque > 0
GROUP BY categoria
ORDER BY produtos_ativos_com_estoque DESC, categoria;

SELECT id, titulo, categoria, tecnica, materia_prima
FROM produtos
WHERE id = 1017;

SELECT c.id_usuario AS comprador_sem_historico
FROM compradores c
WHERE c.id_usuario = 104;
