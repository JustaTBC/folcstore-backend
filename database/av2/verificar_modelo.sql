-- PI4-242: confere a quantidade e as principais constraints do modelo fisico.
-- Rode apos ddl.sql com psql -v ON_ERROR_STOP=1.
DO $$
DECLARE qtd INTEGER;
BEGIN
    SELECT COUNT(*) INTO qtd
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      AND table_name IN (
        'usuarios', 'compradores', 'artesaos', 'administradores',
        'enderecos', 'produtos', 'imagens_produto', 'carrinhos',
        'itens_carrinho', 'pedidos', 'itens_pedido', 'postagens', 'avaliacoes'
      );
    IF qtd <> 13 THEN
        RAISE EXCEPTION 'Falha: esperadas 13 tabelas; encontradas %', qtd;
    END IF;
    RAISE NOTICE 'OK: 13 tabelas do FolcStore encontradas.';
END $$;

SELECT con.contype AS tipo, COUNT(*) AS quantidade
FROM pg_constraint con
JOIN pg_namespace ns ON ns.oid = con.connamespace
WHERE ns.nspname = 'public'
  AND con.conrelid IN (
      SELECT oid FROM pg_class
      WHERE relname IN (
          'usuarios', 'compradores', 'artesaos', 'administradores',
          'enderecos', 'produtos', 'imagens_produto', 'carrinhos',
          'itens_carrinho', 'pedidos', 'itens_pedido', 'postagens', 'avaliacoes'
      )
  )
GROUP BY con.contype ORDER BY con.contype;
-- p = PK, f = FK, c = CHECK (inclusive NOT NULL), u = UNIQUE
