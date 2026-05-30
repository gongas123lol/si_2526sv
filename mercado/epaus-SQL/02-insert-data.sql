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
 * */

START TRANSACTION;

-- Mercados financeiros
INSERT INTO mercado (mercado_id, descricao, nome_curto) VALUES
('PSI', 'Mercado principal de acções portuguesas', 'PSI'),
('LISBOND', 'Mercado português de obrigações corporativas', 'LisBond'),
('TECHLIS', 'Mercado tecnológico de Lisboa', 'TechLis');

-- Instrumentos financeiros
INSERT INTO instrumento (instrumento_id, descricao, mercado) VALUES
('PTGAL0AM0009', 'Galp Energia, SGPS, S.A.', 'PSI'),
('PTEDP0AM0009', 'EDP - Energias de Portugal, S.A.', 'PSI'),
('PTBCP0AM0015', 'Banco Comercial Português, S.A.', 'PSI'),
('PTJMT0AE0001', 'Jerónimo Martins, SGPS, S.A.', 'PSI'),
('PTALT0AE0002', 'Altice Portugal Obrigações 2028', 'LISBOND'),
('PTREN0AM0008', 'REN - Redes Energéticas Nacionais, S.A.', 'LISBOND'),
('PTWEB0AM0001', 'WebLisboa Technologies, S.A.', 'TECHLIS'),
('PTDAT0AM0002', 'Dados do Tejo, S.A.', 'TECHLIS');

-- Triplos recebidos de sistema externo
INSERT INTO triplo_externo (identificador, data_tempo, valor) VALUES
('PTGAL0AM0009', '2026-04-27 09:00:00', 15.21),
('PTGAL0AM0009', '2026-04-27 12:30:00', 15.48),
('PTGAL0AM0009', '2026-04-27 17:30:00', 15.39),
('PTEDP0AM0009', '2026-04-27 09:00:00', 3.88),
('PTEDP0AM0009', '2026-04-27 12:30:00', 3.95),
('PTEDP0AM0009', '2026-04-27 17:30:00', 3.91),
('PTBCP0AM0015', '2026-04-27 09:00:00', 0.42),
('PTBCP0AM0015', '2026-04-27 12:30:00', 0.44),
('PTBCP0AM0015', '2026-04-27 17:30:00', 0.43),
('PTJMT0AE0001', '2026-04-27 09:00:00', 20.15),
('PTJMT0AE0001', '2026-04-27 12:30:00', 20.45),
('PTJMT0AE0001', '2026-04-27 17:30:00', 20.31),
('PTALT0AE0002', '2026-04-27 10:00:00', 101.20),
('PTREN0AM0008', '2026-04-27 10:00:00', 2.61),
('PTWEB0AM0001', '2026-04-27 09:30:00', 8.15),
('PTDAT0AM0002', '2026-04-27 09:30:00', 12.72),
('PTDESCONH01', '2026-04-27 11:15:00', 5.55);

-- Valores diários dos instrumentos
INSERT INTO valor_instrumento_diario
(instrumento_isin, data, valor_minimo, valor_maximo, valor_abertura, valor_fecho) VALUES
('PTGAL0AM0009', '2026-04-24', 14.90, 15.20, 15.00, 15.10),
('PTEDP0AM0009', '2026-04-24', 3.80, 3.92, 3.84, 3.88),
('PTBCP0AM0015', '2026-04-24', 0.40, 0.43, 0.41, 0.42),
('PTJMT0AE0001', '2026-04-24', 19.75, 20.20, 19.90, 20.15),
('PTALT0AE0002', '2026-04-24', 100.80, 101.10, 100.90, 101.00),
('PTREN0AM0008', '2026-04-24', 2.55, 2.62, 2.58, 2.60),
('PTWEB0AM0001', '2026-04-24', 7.80, 8.05, 7.95, 8.00),
('PTDAT0AM0002', '2026-04-24', 12.20, 12.55, 12.30, 12.50),
('PTGAL0AM0009', '2026-04-27', 15.21, 15.48, 15.21, 15.39),
('PTEDP0AM0009', '2026-04-27', 3.88, 3.95, 3.88, 3.91),
('PTBCP0AM0015', '2026-04-27', 0.42, 0.44, 0.42, 0.43),
('PTJMT0AE0001', '2026-04-27', 20.15, 20.45, 20.15, 20.31),
('PTALT0AE0002', '2026-04-27', 101.10, 101.35, 101.20, 101.30),
('PTREN0AM0008', '2026-04-27', 2.58, 2.63, 2.60, 2.61),
('PTWEB0AM0001', '2026-04-27', 8.05, 8.32, 8.15, 8.28),
('PTDAT0AM0002', '2026-04-27', 12.60, 12.95, 12.72, 12.90);

-- Valores diários dos mercados
INSERT INTO valor_mercado_diario
(mercado, data, valor_indice, valor_abertura, variacao_diaria) VALUES
('PSI', '2026-04-24', 39.15, 38.80, 0.35),
('LISBOND', '2026-04-24', 103.48, 103.10, 0.38),
('TECHLIS', '2026-04-24', 20.25, 19.90, 0.35),
('PSI', '2026-04-27', 39.66, 39.15, 0.51),
('LISBOND', '2026-04-27', 103.80, 103.48, 0.32),
('TECHLIS', '2026-04-27', 20.87, 20.25, 0.62);

-- Dados fundamentais dos instrumentos
INSERT INTO dados_fundamentais
(instrumento_isin, variacao_diaria, valor_actual, media_6_meses,
 variacao_6_meses, percentagem_variacao_diaria, percentagem_variacao_6_meses) VALUES
('PTGAL0AM0009', 0.27, 15.39, 14.82, 0.57, 1.78, 3.85),
('PTEDP0AM0009', 0.07, 3.91, 3.76, 0.15, 1.80, 3.99),
('PTBCP0AM0015', 0.02, 0.43, 0.39, 0.04, 4.76, 10.26),
('PTJMT0AE0001', 0.30, 20.31, 19.65, 0.66, 1.49, 3.36),
('PTALT0AE0002', 0.25, 101.30, 100.95, 0.35, 0.25, 0.35),
('PTREN0AM0008', 0.05, 2.61, 2.54, 0.07, 1.92, 2.76),
('PTWEB0AM0001', 0.27, 8.28, 7.62, 0.66, 3.31, 8.66),
('PTDAT0AM0002', 0.35, 12.90, 12.05, 0.85, 2.75, 7.05);

-- Clientes portugueses
INSERT INTO cliente (nif, cartao_cidadao, nome) VALUES
('214587963', '14523678 4 ZX2', 'João Miguel Ferreira'),
('239874561', '15874236 9 AB5', 'Maria Inês Costa'),
('256398741', '16789345 1 CD7', 'Ana Sofia Almeida'),
('287654321', '17364528 3 EF9', 'Pedro Nuno Rodrigues'),
('298765432', '18475639 6 GH1', 'Carolina Matos Silva');

-- Contactos de email
INSERT INTO contacto_email (cliente_nif, descricao, email) VALUES
('214587963', 'Email pessoal', 'joao.ferreira@pessoal.pt'),
('214587963', 'Email profissional', 'joao.ferreira@empresa.pt'),
('239874561', 'Email pessoal', 'maria.costa@pessoal.pt'),
('256398741', 'Email pessoal', 'ana.almeida@pessoal.pt'),
('287654321', 'Email profissional', 'pedro.rodrigues@consultoria.pt'),
('298765432', 'Email pessoal', 'carolina.silva@pessoal.pt');

-- Contactos telefónicos
INSERT INTO contacto_telefone (cliente_nif, descricao, telefone) VALUES
('214587963', 'Telemóvel', '+351912345678'),
('239874561', 'Telemóvel', '+351913456789'),
('256398741', 'Telemóvel', '+351914567890'),
('287654321', 'Telefone de casa', '+351218765432'),
('298765432', 'Telemóvel', '+351915678901');

-- Portefólios
INSERT INTO portefolio (portefolio_id, cliente_nif, nome, valor_total) VALUES
(1, '214587963', 'Reforma Conservadora', 0),
(2, '214587963', 'Tecnologia Lisboa', 0),
(3, '239874561', 'Dividendos Portugal', 0),
(4, '256398741', 'Crescimento 2026', 0),
(5, '287654321', 'Obrigações e Energia', 0),
(6, '298765432', 'Carteira Familiar', 0);

-- Posições dos portefólios
INSERT INTO posicao (portefolio, instrumento_isin, quantidade) VALUES
(1, 'PTGAL0AM0009', 120.0000),
(1, 'PTEDP0AM0009', 350.0000),
(1, 'PTALT0AE0002', 10.0000),
(2, 'PTWEB0AM0001', 200.0000),
(2, 'PTDAT0AM0002', 150.0000),
(3, 'PTJMT0AE0001', 80.0000),
(3, 'PTEDP0AM0009', 500.0000),
(3, 'PTBCP0AM0015', 2000.0000),
(4, 'PTWEB0AM0001', 300.0000),
(4, 'PTGAL0AM0009', 75.0000),
(4, 'PTDAT0AM0002', 100.0000),
(5, 'PTALT0AE0002', 25.0000),
(5, 'PTREN0AM0008', 700.0000),
(6, 'PTJMT0AE0001', 60.0000),
(6, 'PTGAL0AM0009', 50.0000),
(6, 'PTEDP0AM0009', 250.0000),
(6, 'PTBCP0AM0015', 1500.0000);

-- Recalcular valor_total dos portefólios a partir das posições e do valor_actual.
UPDATE portefolio pf
SET valor_total = COALESCE((
    SELECT ROUND(SUM(p.quantidade * df.valor_actual), 2)
    FROM posicao p
    JOIN dados_fundamentais df
      ON df.instrumento_isin = p.instrumento_isin
    WHERE p.portefolio = pf.portefolio_id
), 0);

-- Ajustar sequência do BIGSERIAL, porque foram usados IDs explícitos em portefolio.
SELECT setval(
    pg_get_serial_sequence('portefolio', 'portefolio_id'),
    (SELECT MAX(portefolio_id) FROM portefolio)
);

COMMIT;


