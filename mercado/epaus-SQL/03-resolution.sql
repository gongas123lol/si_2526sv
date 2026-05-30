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
CREATE OR REPLACE FUNCTION fn_validate_nif()
RETURNS TRIGGER AS $$
DECLARE
    digits TEXT := NEW.nif;
    total INTEGER := 0;
    expected INTEGER;
BEGIN
    IF digits !~ '^[0-9]{9}$' THEN
        RAISE EXCEPTION 'NIF % must have exactly 9 digits', NEW.nif;
    END IF;

    FOR i IN 1..8 LOOP
        total := total + substring(digits FROM i FOR 1)::INTEGER * (10 - i);
    END LOOP;

    expected := 11 - (total % 11);
    IF expected >= 10 THEN
        expected := 0;
    END IF;

    IF expected <> substring(digits FROM 9 FOR 1)::INTEGER THEN
        RAISE EXCEPTION 'Invalid NIF %', NEW.nif;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validate_nif
BEFORE INSERT OR UPDATE OF nif ON cliente
FOR EACH ROW EXECUTE FUNCTION fn_validate_nif();
-- endregion

-- region Question 1.b
CREATE OR REPLACE FUNCTION fn_validate_unique_email_contact()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM contacto_email ce
        WHERE ce.cliente_nif = NEW.cliente_nif
          AND lower(ce.email) = lower(NEW.email)
          AND ce.contacto_email_id <> COALESCE(NEW.contacto_email_id, -1)
    ) THEN
        RAISE EXCEPTION 'Duplicate email contact % for client %', NEW.email, NEW.cliente_nif;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validate_unique_phone_contact()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM contacto_telefone ct
        WHERE ct.cliente_nif = NEW.cliente_nif
          AND ct.telefone = NEW.telefone
          AND ct.contacto_telefone_id <> COALESCE(NEW.contacto_telefone_id, -1)
    ) THEN
        RAISE EXCEPTION 'Duplicate phone contact % for client %', NEW.telefone, NEW.cliente_nif;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_unique_email_contact
BEFORE INSERT OR UPDATE ON contacto_email
FOR EACH ROW EXECUTE FUNCTION fn_validate_unique_email_contact();

CREATE OR REPLACE TRIGGER trg_unique_phone_contact
BEFORE INSERT OR UPDATE ON contacto_telefone
FOR EACH ROW EXECUTE FUNCTION fn_validate_unique_phone_contact();
-- endregion

-- region Question 2
CREATE OR REPLACE FUNCTION fx_media_movel(p_days INTEGER, p_instrumento_isin VARCHAR(12))
RETURNS NUMERIC(15,2) AS $$
DECLARE
    result NUMERIC(15,2);
BEGIN
    IF p_days IS NULL OR p_days <= 0 THEN
        RAISE EXCEPTION 'Number of days must be positive';
    END IF;

    SELECT ROUND(AVG(valor_fecho), 2)
    INTO result
    FROM (
        SELECT valor_fecho
        FROM valor_instrumento_diario
        WHERE instrumento_isin = p_instrumento_isin
        ORDER BY data DESC
        LIMIT p_days
    ) recent_values;

    RETURN result;
END;
$$ LANGUAGE plpgsql;
-- endregion

-- region Question 3
CREATE OR REPLACE FUNCTION fx_portefolio_info(p_portefolio_id BIGINT)
RETURNS TABLE (
    instrumento_isin VARCHAR(12),
    quantidade NUMERIC(15,4),
    valor_actual NUMERIC(15,2),
    percentagem_variacao_diaria NUMERIC(7,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.instrumento_isin,
        p.quantidade,
        df.valor_actual,
        COALESCE(
            ROUND(((latest.valor_fecho - previous.valor_fecho) / NULLIF(previous.valor_fecho, 0)) * 100, 2),
            df.percentagem_variacao_diaria
        )::NUMERIC(7,2) AS percentagem_variacao_diaria
    FROM posicao p
    JOIN dados_fundamentais df ON df.instrumento_isin = p.instrumento_isin
    LEFT JOIN LATERAL (
        SELECT vid.valor_fecho, vid.data
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = p.instrumento_isin
        ORDER BY vid.data DESC
        LIMIT 1
    ) latest ON TRUE
    LEFT JOIN LATERAL (
        SELECT vid.valor_fecho
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = p.instrumento_isin
          AND vid.data < latest.data
        ORDER BY vid.data DESC
        LIMIT 1
    ) previous ON TRUE
    WHERE p.portefolio = p_portefolio_id;
END;
$$ LANGUAGE plpgsql;
-- endregion
 
-- region Question 4
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
    JOIN instrumento i ON i.instrumento_id = te.identificador
    GROUP BY i.instrumento_id, te.data_tempo::DATE
    ON CONFLICT (instrumento_isin, data) DO UPDATE
    SET valor_minimo = EXCLUDED.valor_minimo,
        valor_maximo = EXCLUDED.valor_maximo,
        valor_abertura = EXCLUDED.valor_abertura,
        valor_fecho = EXCLUDED.valor_fecho;

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
        JOIN dados_fundamentais df ON df.instrumento_isin = p.instrumento_isin
        WHERE p.portefolio = pf.portefolio_id
    ), 0);
END;
$$;
-- endregion

-- region Question 5
CREATE OR REPLACE VIEW contacto_cliente(nif,carta_cidadao,nome,tipo_contacto,contacto,descricao)
AS
SELECT c.nif,
       c.cartao_cidadao,
       c.nome,
       'email'::VARCHAR(10) AS tipo_contacto,
       ce.email AS contacto,
       ce.descricao
FROM cliente c
JOIN contacto_email ce ON ce.cliente_nif = c.nif
UNION ALL
SELECT c.nif,
       c.cartao_cidadao,
       c.nome,
       'telefone'::VARCHAR(10) AS tipo_contacto,
       ct.telefone AS contacto,
       ct.descricao
FROM cliente c
JOIN contacto_telefone ct ON ct.cliente_nif = c.nif;

CREATE OR REPLACE FUNCTION fn_contacto_cliente_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO cliente (nif, cartao_cidadao, nome)
    VALUES (NEW.nif, NEW.carta_cidadao, NEW.nome)
    ON CONFLICT (nif) DO UPDATE
    SET cartao_cidadao = EXCLUDED.cartao_cidadao,
        nome = EXCLUDED.nome;

    IF lower(NEW.tipo_contacto) = 'email' THEN
        INSERT INTO contacto_email (cliente_nif, descricao, email)
        VALUES (NEW.nif, NEW.descricao, NEW.contacto);
    ELSIF lower(NEW.tipo_contacto) IN ('telefone', 'phone') THEN
        INSERT INTO contacto_telefone (cliente_nif, descricao, telefone)
        VALUES (NEW.nif, NEW.descricao, NEW.contacto);
    ELSE
        RAISE EXCEPTION 'Unknown contact type %', NEW.tipo_contacto;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_contacto_cliente_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cliente
    SET nif = NEW.nif,
        cartao_cidadao = NEW.carta_cidadao,
        nome = NEW.nome
    WHERE nif = OLD.nif;

    IF lower(OLD.tipo_contacto) = 'email' THEN
        UPDATE contacto_email
        SET cliente_nif = NEW.nif,
            descricao = NEW.descricao,
            email = NEW.contacto
        WHERE cliente_nif = OLD.nif
          AND email = OLD.contacto
          AND descricao = OLD.descricao;
    ELSIF lower(OLD.tipo_contacto) = 'telefone' THEN
        UPDATE contacto_telefone
        SET cliente_nif = NEW.nif,
            descricao = NEW.descricao,
            telefone = NEW.contacto
        WHERE cliente_nif = OLD.nif
          AND telefone = OLD.contacto
          AND descricao = OLD.descricao;
    ELSE
        RAISE EXCEPTION 'Unknown contact type %', OLD.tipo_contacto;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_contacto_cliente_insert
INSTEAD OF INSERT ON contacto_cliente
FOR EACH ROW EXECUTE FUNCTION fn_contacto_cliente_insert();

CREATE OR REPLACE TRIGGER trg_contacto_cliente_update
INSTEAD OF UPDATE ON contacto_cliente
FOR EACH ROW EXECUTE FUNCTION fn_contacto_cliente_update();
-- endregion

-- region Other changes
ALTER TABLE cliente
ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION fn_refresh_valor_mercado(p_mercado VARCHAR(20), p_data DATE)
RETURNS VOID AS $$
DECLARE
    current_index NUMERIC(15,2);
    opening_index NUMERIC(15,2);
BEGIN
    SELECT ROUND(SUM(vid.valor_abertura), 2)
    INTO current_index
    FROM instrumento i
    JOIN valor_instrumento_diario vid ON vid.instrumento_isin = i.instrumento_id
    WHERE i.mercado = p_mercado
      AND vid.data = p_data;

    IF current_index IS NULL THEN
        DELETE FROM valor_mercado_diario
        WHERE mercado = p_mercado AND data = p_data;
        RETURN;
    END IF;

    SELECT vmd.valor_indice
    INTO opening_index
    FROM valor_mercado_diario vmd
    WHERE vmd.mercado = p_mercado
      AND vmd.data < p_data
    ORDER BY vmd.data DESC
    LIMIT 1;

    opening_index := COALESCE(opening_index, current_index);

    INSERT INTO valor_mercado_diario (mercado, data, valor_indice, valor_abertura, variacao_diaria)
    VALUES (p_mercado, p_data, current_index, opening_index, ROUND(current_index - opening_index, 2))
    ON CONFLICT (mercado, data) DO UPDATE
    SET valor_indice = EXCLUDED.valor_indice,
        valor_abertura = EXCLUDED.valor_abertura,
        variacao_diaria = EXCLUDED.variacao_diaria;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_refresh_valor_mercado_trigger()
RETURNS TRIGGER AS $$
DECLARE
    market_id VARCHAR(20);
BEGIN
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        SELECT mercado INTO market_id
        FROM instrumento
        WHERE instrumento_id = NEW.instrumento_isin;
        PERFORM fn_refresh_valor_mercado(market_id, NEW.data);
    END IF;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        SELECT mercado INTO market_id
        FROM instrumento
        WHERE instrumento_id = OLD.instrumento_isin;
        PERFORM fn_refresh_valor_mercado(market_id, OLD.data);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_refresh_valor_mercado
AFTER INSERT OR UPDATE OR DELETE ON valor_instrumento_diario
FOR EACH ROW EXECUTE FUNCTION fn_refresh_valor_mercado_trigger();
-- endregion
