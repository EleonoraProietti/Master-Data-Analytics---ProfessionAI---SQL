-- Selezione del DataBase
USE banca;

-- Creazione tabelle temporanee per ogni indicatore
-- 1. Età dei clienti
CREATE TEMPORARY TABLE tmp_eta AS
SELECT 
	id_cliente,
    TIMESTAMPDIFF(YEAR, data_nascita, CURDATE()) AS eta
FROM cliente;

-- 2. Indicatori generali sulle transazioni
CREATE TEMPORARY TABLE tmp_transazioni_generali AS
SELECT
	c.id_cliente,
    SUM(CASE WHEN t.importo < 0 THEN 1 ELSE 0 END) AS num_trans_uscita,
    SUM(CASE WHEN t.importo > 0 THEN 1 ELSE 0 END) AS num_trans_entrata,
    SUM(CASE WHEN t.importo < 0 THEN t.importo ELSE 0 END) AS somma_uscita,
    SUM(CASE WHEN t.importo > 0 THEN t.importo ELSE 0 END) AS somma_entrata
FROM transazioni t
JOIN conto c ON c.id_conto = t.id_conto
GROUP BY c.id_cliente;

-- 3. Numero di conti per cliente
CREATE TEMPORARY TABLE tmp_num_conti AS 
SELECT
	id_cliente,
    COUNT(*) AS num_conti
FROM conto
GROUP BY id_cliente;

-- 4. Numero di conti per tipologia
CREATE TEMPORARY TABLE tmp_conti_pivot AS
SELECT
	c.id_cliente,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto base' THEN 1 ELSE 0 END) AS num_conti_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto business' THEN 1 ELSE 0 END) AS num_conti_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto privati' THEN 1 ELSE 0 END) AS num_conti_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto famiglie' THEN 1 ELSE 0 END) AS num_conti_famiglie
FROM conto c
JOIN tipo_conto tc ON c.id_tipo_conto = c.id_tipo_conto
GROUP BY c.id_cliente;

-- 5. Transazioni per tipologia di conto
CREATE TEMPORARY TABLE tmp_transazioni_pivot AS
SELECT
	c.id_cliente,
    
    -- Conto BASE
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto base' AND t.importo < 0 THEN 1 ELSE 0 END) AS trans_uscita_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto base' AND t.importo > 0 THEN 1 ELSE 0 END) AS trans_entrata_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto base' AND t.importo < 0 THEN t.importo ELSE 0 END) AS importo_uscita_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto base' AND t.importo > 0 THEN t.importo ELSE 0 END) AS importo_entrata_base,
    
    -- Conto BUSINESS
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto business' AND t.importo < 0 THEN 1 ELSE 0 END) AS trans_uscita_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto business' AND t.importo > 0 THEN 1 ELSE 0 END) AS trans_entrata_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto business' AND t.importo < 0 THEN t.importo ELSE 0 END) AS importo_uscita_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto business' AND t.importo > 0 THEN t.importo ELSE 0 END) AS importo_entrata_business,
    
    -- Conto PRIVATI
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto privati' AND t.importo < 0 THEN 1 ELSE 0 END) AS trans_uscita_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto privati' AND t.importo > 0 THEN 1 ELSE 0 END) AS trans_entrata_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto privati' AND t.importo < 0 THEN t.importo ELSE 0 END) AS importo_uscita_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto privati' AND t.importo > 0 THEN t.importo ELSE 0 END) AS importo_entrata_privati,
    
    -- Conto FAMIGLIE
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto famiglie' AND t.importo < 0 THEN 1 ELSE 0 END) AS trans_uscita_famiglie,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto famiglie' AND t.importo > 0 THEN 1 ELSE 0 END) AS trans_entrata_famiglie,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto famiglie' AND t.importo < 0 THEN t.importo ELSE 0 END) AS importo_uscita_famiglie,
    SUM(CASE WHEN tc.desc_tipo_conto = 'conto famiglie' AND t.importo > 0 THEN t.importo ELSE 0 END) AS importo_entrata_famiglie
    
FROM transazioni t
JOIN conto c ON c.id_conto = t.id_conto
JOIN tipo_conto tc ON tc.id_tipo_conto = c.id_tipo_conto
GROUP BY c.id_cliente;

-- Tabella denormalizzata
SELECT
	e.id_cliente,
    e.eta,
    
    COALESCE(g.num_trans_uscita, 0) AS num_trans_uscita,
    COALESCE(g.num_trans_entrata, 0) AS num_trans_entrata,
    COALESCE(g.somma_uscita, 0) AS somma_uscita,
    COALESCE(g.somma_entrata, 0) AS somma_entrata,
    
    COALESCE(nc.num_conti, 0) AS num_conti,
    
   COALESCE(cp.num_conti_base, 0) AS num_conti_base,
   COALESCE(cp.num_conti_business, 0) AS num_conti_business,
   COALESCE(cp.num_conti_privati, 0) AS num_conti_privati,
   COALESCE(cp.num_conti_famiglie, 0) AS num_conti_famiglie,
   
   COALESCE(tp.trans_uscita_base, 0) AS tras_uscita_base,
   COALESCE(tp.trans_entrata_base, 0) AS trans_entrata_base,
   COALESCE(tp.importo_uscita_base, 0) AS importo_uscita_base,
   COALESCE(tp.importo_entrata_base, 0) AS importo_entrata_base,
   
   COALESCE(tp.trans_uscita_business, 0) AS trans_uscita_business,
   COALESCE(tp.trans_entrata_business, 0) AS trans_entrata_business,
   COALESCE(tp.importo_uscita_business, 0) AS importo_uscita_business,
   COALESCE(tp.importo_entrata_business, 0) AS importo_entrata_business,
   
   COALESCE(tp.trans_uscita_privati, 0) AS trans_uscita_privati,
   COALESCE(tp.trans_entrata_privati, 0) AS trans_entrata_privati,
   COALESCE(tp.importo_uscita_privati, 0) AS importo_uscita_privati,
   COALESCE(tp.importo_entrata_privati, 0) AS importo_entrata_privati,
   
   COALESCE(tp.trans_uscita_famiglie, 0) AS trans_uscita_famiglie,
   COALESCE(tp.trans_entrata_famiglie, 0) AS trans_entrata_famiglie,
   COALESCE(tp.importo_uscita_famiglie, 0) AS importo_uscita_famiglie,
   COALESCE(tp.importo_entrata_famiglie, 0) AS importo_entrata_famiglie
   
FROM tmp_eta e
LEFT JOIN tmp_transazioni_generali g ON g.id_cliente = e.id_cliente
LEFT JOIN tmp_num_conti nc ON nc.id_cliente = e.id_cliente
LEFT JOIN tmp_conti_pivot cp ON cp.id_cliente = e.id_cliente
LEFT JOIN tmp_transazioni_pivot tp ON tp.id_cliente = e.id_cliente;