-- PI4-242: duas falhas controladas. Nao insere registros permanentes.
-- Pode ser executado em banco sem seed, depois do ddl.sql.
-- Os DO blocks capturam a falha esperada, para que o comando psql termine com exit code 0.
DO $$
BEGIN
    BEGIN
        INSERT INTO usuarios (nome, email, senha)
        VALUES ('', 'teste-check@invalid.example', 'hash_de_teste');
        RAISE EXCEPTION 'FALHA: o CHECK permitiu usuario sem nome';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK teste 1: CHECK bloqueou usuario com nome vazio.';
    END;
END $$;

DO $$
BEGIN
    BEGIN
        INSERT INTO compradores (id_usuario) VALUES (-999999);
        RAISE EXCEPTION 'FALHA: a FK permitiu comprador sem usuario';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK teste 2: FOREIGN KEY bloqueou comprador sem usuario.';
    END;
END $$;
