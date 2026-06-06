/*
 * ISEL-DEI-SisInf
 * ND 2022-2026
 *
 *
 * Information Systems Project - Active Databases
 * Didactic material to support
 * the Information Systems course
 *
 *  * */

/* ### DO NOT CHANGE OR REMOVE THE MARKERS BELOW
 * ### ONLY WRITE to THE TODO ZONE
 * ### */


-- region Question 1.a
CREATE OR REPLACE FUNCTION fun_trigger_1a()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nif !~ '^[0-9]{9}$' THEN
        RAISE EXCEPTION 'NIF invalido: deve conter exactamente 9 digitos';
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_1a ON cliente;
CREATE TRIGGER trigger_1a
BEFORE INSERT OR UPDATE OF nif ON cliente
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1a();
-- endregion

-- region Question 1.b
CREATE OR REPLACE FUNCTION fun_trigger_1b_email()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM contacto_email ce
        WHERE ce.cliente_nif = NEW.cliente_nif
          AND lower(ce.email) = lower(NEW.email)
          AND ce.contacto_email_id <> COALESCE(NEW.contacto_email_id, -1)
    ) THEN
        RAISE EXCEPTION 'Ja existe um contacto de email igual associado a este cliente';
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_trigger_1b_telefone()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM contacto_telefone ct
        WHERE ct.cliente_nif = NEW.cliente_nif
          AND ct.telefone = NEW.telefone
          AND ct.contacto_telefone_id <> COALESCE(NEW.contacto_telefone_id, -1)
    ) THEN
        RAISE EXCEPTION 'Ja existe um contacto telefonico igual associado a este cliente';
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_1b_email ON contacto_email;
CREATE TRIGGER trigger_1b_email
BEFORE INSERT OR UPDATE ON contacto_email
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1b_email();

DROP TRIGGER IF EXISTS trigger_1b_telefone ON contacto_telefone;
CREATE TRIGGER trigger_1b_telefone
BEFORE INSERT OR UPDATE ON contacto_telefone
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1b_telefone();
-- endregion

-- region Question 2
CREATE OR REPLACE FUNCTION fx_media_movel(p_days INTEGER, p_instrumento_isin VARCHAR(12))
RETURNS NUMERIC(15,2) AS $$
DECLARE
    media NUMERIC(15,2);
BEGIN
    IF p_days IS NULL OR p_days <= 0 THEN
        RAISE EXCEPTION 'O numero de dias deve ser positivo';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM instrumento i
        WHERE i.instrumento_id = p_instrumento_isin
    ) THEN
        RAISE EXCEPTION 'Instrumento inexistente: %', p_instrumento_isin;
    END IF;

    SELECT ROUND(AVG(valor_fecho), 2)
    INTO media
    FROM (
        SELECT vid.valor_fecho
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = p_instrumento_isin
        ORDER BY vid.data DESC
        LIMIT p_days
    ) ultimos_dias;

    RETURN media;
END;
$$
LANGUAGE plpgsql;
-- endregion

-- region Question 3
CREATE OR REPLACE FUNCTION fx_portefolio_info(p_portefolio_id BIGINT)
RETURNS TABLE (
    instrumento_isin            VARCHAR(12),
    quantidade                  NUMERIC(15,4),
    valor_actual                NUMERIC(15,2),
    percentagem_variacao_diaria NUMERIC(7,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.instrumento_isin,
        p.quantidade,
        df.valor_actual,
        COALESCE(
            ROUND(((hoje.valor_fecho - ontem.valor_fecho) / NULLIF(ontem.valor_fecho, 0)) * 100, 2),
            df.percentagem_variacao_diaria
        )::NUMERIC(7,2) AS percentagem_variacao_diaria
    FROM posicao p
    JOIN dados_fundamentais df
      ON df.instrumento_isin = p.instrumento_isin
    LEFT JOIN LATERAL (
        SELECT vid.valor_fecho
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = p.instrumento_isin
        ORDER BY vid.data DESC
        LIMIT 1
    ) hoje ON TRUE
    LEFT JOIN LATERAL (
        SELECT vid.valor_fecho
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = p.instrumento_isin
          AND vid.data < (
              SELECT MAX(vid2.data)
              FROM valor_instrumento_diario vid2
              WHERE vid2.instrumento_isin = p.instrumento_isin
          )
        ORDER BY vid.data DESC
        LIMIT 1
    ) ontem ON TRUE
    WHERE p.portefolio = p_portefolio_id
    ORDER BY p.instrumento_isin;
END;
$$
LANGUAGE plpgsql;
-- endregion

-- region Question 4
DROP TRIGGER IF EXISTS trigger_sync_mercado_diario ON valor_instrumento_diario;
DROP FUNCTION IF EXISTS fun_sync_mercado_diario();
DROP FUNCTION IF EXISTS fx_actualiza_mercado_diario(VARCHAR(20), DATE);

CREATE OR REPLACE PROCEDURE p_actualizaValorDiario()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO valor_instrumento_diario (
        instrumento_isin,
        data,
        valor_minimo,
        valor_maximo,
        valor_abertura,
        valor_fecho
    )
    SELECT
        i.instrumento_id,
        te.data_tempo::DATE,
        MIN(te.valor),
        MAX(te.valor),
        (ARRAY_AGG(te.valor ORDER BY te.data_tempo ASC))[1],
        (ARRAY_AGG(te.valor ORDER BY te.data_tempo DESC))[1]
    FROM triplo_externo te
    JOIN instrumento i
      ON i.instrumento_id = te.identificador
    GROUP BY i.instrumento_id, te.data_tempo::DATE
    ON CONFLICT (instrumento_isin, data) DO UPDATE
    SET valor_minimo = EXCLUDED.valor_minimo,
        valor_maximo = EXCLUDED.valor_maximo,
        valor_abertura = EXCLUDED.valor_abertura,
        valor_fecho = EXCLUDED.valor_fecho;

    INSERT INTO valor_mercado_diario (
        mercado,
        data,
        valor_indice,
        valor_abertura,
        variacao_diaria
    )
    SELECT
        mercado_dia.mercado,
        mercado_dia.data,
        mercado_dia.valor_indice,
        COALESCE(anterior.valor_indice, mercado_dia.valor_indice) AS valor_abertura,
        ROUND(mercado_dia.valor_indice - COALESCE(anterior.valor_indice, mercado_dia.valor_indice), 2)
    FROM (
        SELECT
            i.mercado,
            vid.data,
            ROUND(SUM(vid.valor_abertura), 2) AS valor_indice
        FROM valor_instrumento_diario vid
        JOIN instrumento i
          ON i.instrumento_id = vid.instrumento_isin
        GROUP BY i.mercado, vid.data
    ) mercado_dia
    LEFT JOIN LATERAL (
        SELECT vmd.valor_indice
        FROM valor_mercado_diario vmd
        WHERE vmd.mercado = mercado_dia.mercado
          AND vmd.data < mercado_dia.data
        ORDER BY vmd.data DESC
        LIMIT 1
    ) anterior ON TRUE
    ON CONFLICT (mercado, data) DO UPDATE
    SET valor_indice = EXCLUDED.valor_indice,
        valor_abertura = EXCLUDED.valor_abertura,
        variacao_diaria = EXCLUDED.variacao_diaria;

    INSERT INTO dados_fundamentais (
        instrumento_isin,
        variacao_diaria,
        valor_actual,
        media_6_meses,
        variacao_6_meses,
        percentagem_variacao_diaria,
        percentagem_variacao_6_meses
    )
    SELECT
        latest.instrumento_isin,
        ROUND(latest.valor_maximo - latest.valor_minimo, 2),
        latest.valor_fecho,
        six_months.media_6_meses,
        ROUND(latest.valor_fecho - six_months.media_6_meses, 2),
        ROUND(((latest.valor_maximo - latest.valor_minimo) / NULLIF(latest.valor_abertura, 0)) * 100, 2),
        ROUND(((latest.valor_fecho - six_months.media_6_meses) / NULLIF(six_months.media_6_meses, 0)) * 100, 2)
    FROM (
        SELECT DISTINCT ON (vid.instrumento_isin) vid.*
        FROM valor_instrumento_diario vid
        ORDER BY vid.instrumento_isin, vid.data DESC
    ) latest
    JOIN LATERAL (
        SELECT ROUND(AVG(vid.valor_fecho), 2) AS media_6_meses
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = latest.instrumento_isin
          AND vid.data >= latest.data - INTERVAL '6 months'
          AND vid.data <= latest.data
    ) six_months ON TRUE
    ON CONFLICT (instrumento_isin) DO UPDATE
    SET variacao_diaria = EXCLUDED.variacao_diaria,
        valor_actual = EXCLUDED.valor_actual,
        media_6_meses = EXCLUDED.media_6_meses,
        variacao_6_meses = EXCLUDED.variacao_6_meses,
        percentagem_variacao_diaria = EXCLUDED.percentagem_variacao_diaria,
        percentagem_variacao_6_meses = EXCLUDED.percentagem_variacao_6_meses;

    UPDATE portefolio pf
    SET valor_total = COALESCE((
        SELECT ROUND(SUM(p.quantidade * df.valor_actual), 2)
        FROM posicao p
        JOIN dados_fundamentais df
          ON df.instrumento_isin = p.instrumento_isin
        WHERE p.portefolio = pf.portefolio_id
    ), 0);
END;
$$;
-- endregion
-- region Question 5
DROP VIEW IF EXISTS contacto_cliente CASCADE;

CREATE VIEW contacto_cliente(nif,carta_cidadao,nome,tipo_contacto,contacto,descricao)
AS
SELECT
    c.nif,
    c.cartao_cidadao,
    c.nome,
    'EMAIL'::VARCHAR(10) AS tipo_contacto,
    ce.email AS contacto,
    ce.descricao
FROM cliente c
JOIN contacto_email ce
  ON ce.cliente_nif = c.nif
UNION ALL
SELECT
    c.nif,
    c.cartao_cidadao,
    c.nome,
    'TELEFONE'::VARCHAR(10) AS tipo_contacto,
    ct.telefone AS contacto,
    ct.descricao
FROM cliente c
JOIN contacto_telefone ct
  ON ct.cliente_nif = c.nif;

CREATE OR REPLACE FUNCTION fun_contacto_cliente_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO cliente (nif, cartao_cidadao, nome)
    VALUES (NEW.nif, NEW.carta_cidadao, NEW.nome)
    ON CONFLICT (nif) DO UPDATE
    SET cartao_cidadao = EXCLUDED.cartao_cidadao,
        nome = EXCLUDED.nome;

    IF upper(NEW.tipo_contacto) IN ('EMAIL', 'E-MAIL') THEN
        INSERT INTO contacto_email (cliente_nif, descricao, email)
        VALUES (NEW.nif, NEW.descricao, NEW.contacto);
    ELSIF upper(NEW.tipo_contacto) IN ('TELEFONE', 'TELEFONO', 'PHONE') THEN
        INSERT INTO contacto_telefone (cliente_nif, descricao, telefone)
        VALUES (NEW.nif, NEW.descricao, NEW.contacto);
    ELSE
        RAISE EXCEPTION 'Tipo de contacto invalido: %', NEW.tipo_contacto;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_contacto_cliente_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nif <> OLD.nif THEN
        RAISE EXCEPTION 'Nao e permitido alterar o NIF atraves da vista contacto_cliente';
    END IF;

    UPDATE cliente c
    SET cartao_cidadao = NEW.carta_cidadao,
        nome = NEW.nome
    WHERE c.nif = OLD.nif;

    IF upper(OLD.tipo_contacto) IN ('EMAIL', 'E-MAIL') THEN
        IF upper(NEW.tipo_contacto) IN ('EMAIL', 'E-MAIL') THEN
            UPDATE contacto_email ce
            SET cliente_nif = NEW.nif,
                descricao = NEW.descricao,
                email = NEW.contacto
            WHERE ce.cliente_nif = OLD.nif
              AND ce.email = OLD.contacto
              AND ce.descricao = OLD.descricao;
        ELSIF upper(NEW.tipo_contacto) IN ('TELEFONE', 'TELEFONO', 'PHONE') THEN
            DELETE FROM contacto_email ce
            WHERE ce.cliente_nif = OLD.nif
              AND ce.email = OLD.contacto
              AND ce.descricao = OLD.descricao;

            INSERT INTO contacto_telefone (cliente_nif, descricao, telefone)
            VALUES (NEW.nif, NEW.descricao, NEW.contacto);
        ELSE
            RAISE EXCEPTION 'Tipo de contacto invalido: %', NEW.tipo_contacto;
        END IF;
    ELSIF upper(OLD.tipo_contacto) IN ('TELEFONE', 'TELEFONO', 'PHONE') THEN
        IF upper(NEW.tipo_contacto) IN ('TELEFONE', 'TELEFONO', 'PHONE') THEN
            UPDATE contacto_telefone ct
            SET cliente_nif = NEW.nif,
                descricao = NEW.descricao,
                telefone = NEW.contacto
            WHERE ct.cliente_nif = OLD.nif
              AND ct.telefone = OLD.contacto
              AND ct.descricao = OLD.descricao;
        ELSIF upper(NEW.tipo_contacto) IN ('EMAIL', 'E-MAIL') THEN
            DELETE FROM contacto_telefone ct
            WHERE ct.cliente_nif = OLD.nif
              AND ct.telefone = OLD.contacto
              AND ct.descricao = OLD.descricao;

            INSERT INTO contacto_email (cliente_nif, descricao, email)
            VALUES (NEW.nif, NEW.descricao, NEW.contacto);
        ELSE
            RAISE EXCEPTION 'Tipo de contacto invalido: %', NEW.tipo_contacto;
        END IF;
    ELSE
        RAISE EXCEPTION 'Tipo de contacto invalido: %', OLD.tipo_contacto;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fun_contacto_cliente_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF upper(OLD.tipo_contacto) IN ('EMAIL', 'E-MAIL') THEN
        DELETE FROM contacto_email ce
        WHERE ce.cliente_nif = OLD.nif
          AND ce.email = OLD.contacto
          AND ce.descricao = OLD.descricao;
    ELSIF upper(OLD.tipo_contacto) IN ('TELEFONE', 'TELEFONO', 'PHONE') THEN
        DELETE FROM contacto_telefone ct
        WHERE ct.cliente_nif = OLD.nif
          AND ct.telefone = OLD.contacto
          AND ct.descricao = OLD.descricao;
    ELSE
        RAISE EXCEPTION 'Tipo de contacto invalido: %', OLD.tipo_contacto;
    END IF;

    RETURN OLD;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_contacto_cliente_insert ON contacto_cliente;
CREATE TRIGGER trigger_contacto_cliente_insert
INSTEAD OF INSERT ON contacto_cliente
FOR EACH ROW EXECUTE FUNCTION fun_contacto_cliente_insert();

DROP TRIGGER IF EXISTS trigger_contacto_cliente_update ON contacto_cliente;
CREATE TRIGGER trigger_contacto_cliente_update
INSTEAD OF UPDATE ON contacto_cliente
FOR EACH ROW EXECUTE FUNCTION fun_contacto_cliente_update();

DROP TRIGGER IF EXISTS trigger_contacto_cliente_delete ON contacto_cliente;
CREATE TRIGGER trigger_contacto_cliente_delete
INSTEAD OF DELETE ON contacto_cliente
FOR EACH ROW EXECUTE FUNCTION fun_contacto_cliente_delete();
-- endregion

-- region Other changes
ALTER TABLE cliente
ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS ux_contacto_email_cliente_email
ON contacto_email (cliente_nif, lower(email));

CREATE UNIQUE INDEX IF NOT EXISTS ux_contacto_telefone_cliente_telefone
ON contacto_telefone (cliente_nif, telefone);
-- endregion
