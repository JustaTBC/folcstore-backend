-- PI4-243 | Tres testes de falha proposital sem persistencia de dados.
-- Os erros esperados sao capturados e relatados como NOTICE: OK.
-- Requer a PI4-242 criada e o PI4-243 seed aplicado.
-- O ROLLBACK final garante que nenhum teste altere dados permanentemente.

BEGIN;

-- Caso 1: preco negativo deve violar CHECK.
DO $teste_preco$
DECLARE
    recusado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO produtos
            (titulo, descricao, tecnica, regiao_producao, categoria,
             preco, quantidade_estoque, id_artesao)
        VALUES ('Produto inválido de teste', 'Teste de CHECK sem dados reais',
                'Teste', 'Região Exemplo', 'Teste', -9.90, 1, 201);
    EXCEPTION WHEN check_violation THEN
        recusado := TRUE;
    END;

    IF NOT recusado THEN
        RAISE EXCEPTION 'FALHA: preco negativo foi aceito pela base.';
    END IF;
    RAISE NOTICE 'OK teste 1: CHECK bloqueou produto com preco negativo.';
END
$teste_preco$;

-- Caso 2: subtotal precisa ser exatamente quantidade * preco_unitario.
DO $teste_subtotal$
DECLARE
    recusado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO itens_pedido
            (id_pedido, id_produto, quantidade, preco_unitario, subtotal)
        VALUES (1303, 1017, 2, 10.00, 19.99);
    EXCEPTION WHEN check_violation THEN
        recusado := TRUE;
    END;

    IF NOT recusado THEN
        RAISE EXCEPTION 'FALHA: subtotal incorreto foi aceito pela base.';
    END IF;
    RAISE NOTICE 'OK teste 2: CHECK bloqueou subtotal incorreto.';
END
$teste_subtotal$;

-- Caso 3: FK para artesao inexistente deve ser bloqueada.
DO $teste_fk$
DECLARE
    recusado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO postagens
            (transportadora, codigo_rastreio, id_pedido, id_artesao)
        VALUES ('Transportadora Exemplo', 'TESTE-INVALIDO', 1301, 999999);
    EXCEPTION WHEN foreign_key_violation THEN
        recusado := TRUE;
    END;

    IF NOT recusado THEN
        RAISE EXCEPTION 'FALHA: postagem com artesao inexistente foi aceita.';
    END IF;
    RAISE NOTICE 'OK teste 3: FOREIGN KEY bloqueou artesao inexistente.';
END
$teste_fk$;

ROLLBACK;
