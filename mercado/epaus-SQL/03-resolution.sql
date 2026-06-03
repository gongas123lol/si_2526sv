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
CREATE OR REPLACE FUNCTION fun_trigger_1a
RETURNS TRIGGER AS $$
BEGIN
    IF length(new.nif) <> 9:
        RAISE EXCEPTION 'NIF invalido, nao tem 9 digitos';
    END IF;
    --bloco try catch a dar cast para bigint
    BEGIN
        PERFORM new.nif::BIGINT;
    EXCEPTION
        RAISE EXCEPTION 'NIF invalido, contem letras';

    RETURN NEW;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_1a
BEFORE INSERT OR UPDATE OF nif ON cliente
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1a();
-- endregion

-- region Question 1.b
CREATE OR REPLACE FUNCTION fun_trigger_1b_email
RETURNS TRIGGER as $$
BEGIN
    IF EXISTS(
        SELECT * FROM contacto_email
         WHERE contacto_email.cliente_nif == new.cliente_nif AND
          contacto_email.email <> new.email
    ) THEN
        RAISE EXCEPTION 'já existe um contacto igual associado a este user';
        END IF;

CREATE OR REPLACE FUNCTION fun_trigger_1b_telefone
RETURNS TRIGGER as $$
BEGIN
    IF EXISTS(
        SELECT * FROM contacto_telefone
         WHERE contacto_telefone.cliente_nif == new.cliente_nif AND
          contacto_telefone.telefone <> new.telefone
    ) THEN
        RAISE EXCEPTION 'já existe um contacto igual associado a este user';
        END IF;
    
CREATE OR REPLACE TRIGGER trigger_1b_email
BEFORE INSERT OR UPDATE ON contacto_email
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1b_email();

CREATE OR REPLACE TRIGGER trigger_1b_telefone
BEFORE INSERT OR UPDATE ON contacto_telefone
FOR EACH ROW EXECUTE FUNCTION fun_trigger_1b_telefone();
-- endregion

-- region Question 2
CREATE OR REPLACE FUNCTION fx_media_movel(p_days INTEGER, p_instrumento_isin VARCHAR(12))
RETURNS NUMERIC(10,2) AS $$
DECLARE
    media NUMERIC(10,2);
BEGIN
    IF p_days <= 0 THEN
        RAISE EXCEPTION 'dias não podem ter valores negativos';
    END IF;

    SELECT ROUND(AVG(valor_fecho), 2)
    INTO media
    FROM (
        SELECT valor_fecho FROM valor_instrumento_diario
        WHERE instrumento_isin = p_instrumento_isin
        ORDER BY data DESC
        LIMIT p_days
    ) ultimos_dias;

    RETURN media;
END;
$$ LANGUAGE plpgsql;
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
DECLARE
    pos        RECORD;
    v_atual    NUMERIC(15,2);
    v_hoje     NUMERIC(15,2);
    v_ontem    NUMERIC(15,2);
    v_variacao NUMERIC(7,2);
BEGIN
    FOR pos IN
        SELECT p.instrumento_isin, p.quantidade
        FROM posicao p
        WHERE p.portefolio = p_portefolio_id
    LOOP
        SELECT df.valor_actual INTO v_atual
        FROM dados_fundamentais df
        WHERE df.instrumento_isin = pos.instrumento_isin;

        SELECT vid.valor_fecho INTO v_hoje
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = pos.instrumento_isin
        ORDER BY vid.data DESC
        LIMIT 1;

        SELECT vid.valor_fecho INTO v_ontem
        FROM valor_instrumento_diario vid
        WHERE vid.instrumento_isin = pos.instrumento_isin
          AND vid.data < (
              SELECT MAX(data)
              FROM valor_instrumento_diario
              WHERE instrumento_isin = pos.instrumento_isin
          )
        ORDER BY vid.data DESC
        LIMIT 1;

        IF v_ontem IS NOT NULL AND v_ontem <> 0 THEN
            SELECT ROUND(((v_hoje - v_ontem) / v_ontem) * 100, 2) INTO v_variacao;
        ELSE
            SELECT df.percentagem_variacao_diaria INTO v_variacao
            FROM dados_fundamentais df
            WHERE df.instrumento_isin = pos.instrumento_isin;
        END IF;

        SELECT pos.instrumento_isin, pos.quantidade, v_atual, v_variacao
        INTO instrumento_isin, quantidade, valor_actual, percentagem_variacao_diaria;

        RETURN NEXT;
    END LOOP;
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
--TODO
-- endregion

-- region Other changes
--TODO
-- endregion

