/*
 * ISEL-DEI-SisInf
 * ND 2022-2026
 *
 *   
 * Information Systems Project - Active Databases
 * Didactic material to support 
 * the Information Systems course
 *
 * The examples may not be complete and/or totally correct.
 * They are made available for teaching purposes and should 
 * be corrected if necessary. 
 *
 * CHANGES SHOULD BE DONE IN THE 03-resolution.sql FILE!!!!
 * */

START TRANSACTION;
DROP TABLE IF exists contacto_email;
DROP TABLE IF exists contacto_telefone;
DROP VIEW IF exists valor_posicao;
DROP TABLE IF exists posicao;
DROP TABLE IF exists portefolio;
DROP TABLE IF exists cliente;
DROP TABLE IF exists dados_fundamentais;
DROP TABLE IF exists valor_instrumento_diario;
DROP TABLE IF exists triplo_externo;
DROP TABLE IF EXISTS instrumento;
DROP TABLE IF EXISTS valor_mercado_diario;
DROP TABLE IF EXISTS mercado;

CREATE TABLE triplo_externo (
    identificador VARCHAR(12) NOT NULL,
    data_tempo TIMESTAMP NOT NULL,
    valor NUMERIC(15,2) NOT NULL,
    PRIMARY KEY (identificador, data_tempo)
);

CREATE TABLE mercado (
    mercado_id VARCHAR(20) PRIMARY KEY,
    descricao TEXT NOT NULL,
    nome_curto VARCHAR(50) NOT NULL
);
CREATE TABLE valor_mercado_diario (
    mercado VARCHAR(20) NOT NULL REFERENCES mercado(mercado_id),
    data DATE NOT NULL,
    valor_indice NUMERIC(15,2) NOT NULL,
    valor_abertura NUMERIC(15,2) NOT NULL,
    variacao_diaria NUMERIC(15,2) NULL,
    PRIMARY KEY (mercado, data)
);


CREATE TABLE instrumento (
    instrumento_id VARCHAR(12) PRIMARY KEY,
    descricao varchar(256) NOT NULL,
    mercado VARCHAR(20) NOT NULL REFERENCES mercado(mercado_id)
);


CREATE TABLE valor_instrumento_diario (
    instrumento_isin VARCHAR(12) NOT NULL REFERENCES instrumento(instrumento_id),
    data DATE NOT NULL,
    valor_minimo NUMERIC(15,2) NOT NULL,
    valor_maximo NUMERIC(15,2) NOT NULL,
    valor_abertura NUMERIC(15,2) NOT NULL,
    valor_fecho NUMERIC(15,2) NOT NULL,
    PRIMARY KEY (instrumento_isin, data)
);

CREATE TABLE dados_fundamentais (
    instrumento_isin VARCHAR(12) PRIMARY KEY REFERENCES instrumento(instrumento_id),
    variacao_diaria NUMERIC(15,2) NOT NULL,
    valor_actual NUMERIC(15,2) NOT NULL,
    media_6_meses NUMERIC(15,2) NOT NULL,
    variacao_6_meses NUMERIC(15,2) NOT NULL,
    percentagem_variacao_diaria NUMERIC(7,2) NOT NULL,
    percentagem_variacao_6_meses NUMERIC(7,2) NOT NULL
);

CREATE TABLE cliente (
    nif VARCHAR(20) PRIMARY KEY,
    cartao_cidadao VARCHAR(20) UNIQUE NOT NULL,
    nome VARCHAR(256) NOT NULL
);

CREATE TABLE portefolio (
    portefolio_id BIGSERIAL PRIMARY KEY,
    cliente_nif VARCHAR(20) NOT NULL REFERENCES cliente(nif),
    nome VARCHAR(100) NOT NULL,
    valor_total NUMERIC(15,2) NOT NULL DEFAULT 0,
    UNIQUE (cliente_nif, nome)
);

CREATE TABLE posicao (
    portefolio BIGINT NOT NULL REFERENCES portefolio(portefolio_id),
    instrumento_isin VARCHAR(12) NOT NULL REFERENCES instrumento(instrumento_id),
    quantidade NUMERIC(15,4) NOT NULL CHECK (quantidade > 0),
    PRIMARY KEY (portefolio, instrumento_isin)
);


CREATE TABLE contacto_email (
    contacto_email_id BIGSERIAL PRIMARY KEY,
    cliente_nif VARCHAR(20) NOT NULL REFERENCES cliente(nif),
    descricao VARCHAR(50) NOT NULL,
    email VARCHAR(254) NOT NULL
);
CREATE TABLE contacto_telefone (
    contacto_telefone_id BIGSERIAL PRIMARY KEY,
    cliente_nif VARCHAR(20) NOT NULL REFERENCES cliente(nif),
    descricao VARCHAR(50) NOT NULL,
    telefone VARCHAR(30) NOT NULL
  
);

CREATE OR REPLACE VIEW valor_posicao AS
SELECT
    p.portefolio,
    p.instrumento_isin,
    p.quantidade,
    df.valor_actual,
    ROUND(p.quantidade * df.valor_actual, 2) AS valor_total
FROM posicao p
JOIN dados_fundamentais df
    ON df.instrumento_isin = p.instrumento_isin;
COMMIT;
