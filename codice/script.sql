USE VigiliDelFuoco;


## Vincoli esprimibili tramite trigger (si veda sezione 1.4)
DELIMITER $$

-- Vincoli su chiamata (V1):

DROP TRIGGER IF EXISTS Check_Chiamata_Insert $$
CREATE TRIGGER Check_Chiamata_Insert BEFORE INSERT ON Chiamata FOR EACH ROW
BEGIN
    IF NEW.OrarioFineChiam <= NEW.OrarioInizioChiam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore V1: L'orario di fine deve essere successivo a quello di inizio";
    END IF;
END $$


DROP TRIGGER IF EXISTS Check_Chiamata_Update $$
CREATE TRIGGER Check_Chiamata_Update BEFORE UPDATE ON Chiamata FOR EACH ROW
BEGIN
    IF NEW.OrarioFineChiam <= NEW.OrarioInizioChiam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore V1: L'orario di fine deve essere successivo a quello di inizio";
    END IF;
END $$

-- Vincoli sull' intervento (V1 e V4): Coerenza orari e priorità Intervento
DROP TRIGGER IF EXISTS Check_Intervento_Insert $$
CREATE TRIGGER Check_Intervento_Insert BEFORE INSERT ON Intervento FOR EACH ROW
BEGIN
    DECLARE InizioIntervento DATETIME;
    
    IF NEW.PrioritàInt < 1 OR NEW.PrioritàInt > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V4: Priorità deve essere tra 1 e 5.';
    END IF;

    SELECT OrarioFineChiam INTO InizioIntervento FROM Chiamata WHERE CodChiam = NEW.CodChiam;
   
    IF NEW.OraFineInt <= InizioIntervento THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V1: Fine intervento deve essere successiva a inizio intervento/fine chiamata.';
    END IF;
    #praticamente preleviamo l'orario di fine chiamata, lo memorizzo in una variabile di tipo data e poi faccio 
    #il controllo con l'orario che sto tentando di inserire
END $$

-- Vincoli V2, V4, V6 sulla manutenzione (check su date, importi e autorizzazione firma)
DROP TRIGGER IF EXISTS Check_Manutenzione_Insert $$
CREATE TRIGGER Check_Manutenzione_Insert BEFORE INSERT ON Manutenzione FOR EACH ROW
BEGIN
    DECLARE v_AbilitFirma BOOLEAN;
    DECLARE v_Mansione VARCHAR(50);

    IF NEW.DataSvolgManut < NEW.DataRichiesta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V2: Data svolgimento antecedente alla richiesta.';
    END IF;

    IF NEW.SpesaManut < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V4: Spesa deve essere positiva.';
    END IF;

    SELECT AbilitFirma, MansioneAmm INTO v_AbilitFirma, v_Mansione FROM Dipendente WHERE CodDip = NEW.CodDip;
    
    IF v_Mansione IS NULL OR v_AbilitFirma = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V6: Richiede amministrativo con firma abilitata.';
    END IF;
END $$

-- Vincolo V3 e V4: Controlli sui dipendenti (Date e stipendio)
DROP TRIGGER IF EXISTS Check_Dipendente_Insert $$
CREATE TRIGGER Check_Dipendente_Insert BEFORE INSERT ON Dipendente FOR EACH ROW
BEGIN
    IF NEW.Stipendio <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V4: Stipendio deve essere positivo.';
    END IF;
	#curdate mi serve per la data corrente
    IF NEW.AnnoAssunzione > YEAR(CURDATE()) OR NEW.DataEntrata > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V3: Le date non possono essere future, a meno di viaggiare nel tempo.';
    END IF;
END $$

-- Vincolo V3: Controlli sul mezzo (data)
DROP TRIGGER IF EXISTS Check_Mezzo_Insert $$
CREATE TRIGGER Check_Mezzo_Insert BEFORE INSERT ON Mezzo FOR EACH ROW
BEGIN
    IF NEW.AnnoFabbMezzo > YEAR(CURDATE()) OR NEW.DataUltManut > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V3: Le date non possono essere future.';
    END IF;
END $$

-- Vincolo V3: Controlli sulla squadra (data di costituzione)
DROP TRIGGER IF EXISTS Check_Squadra_Insert $$
CREATE TRIGGER Check_Squadra_Insert BEFORE INSERT ON Squadra FOR EACH ROW
BEGIN
    IF NEW.DataCostit > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V3: Le date non possono essere future.';
    END IF;
END $$

-- Vincolo V7: Idoneità Mezzo (Revisione < 1 anno)
DROP TRIGGER IF EXISTS Check_Impiego_Mezzo $$
CREATE TRIGGER Check_Impiego_Mezzo BEFORE INSERT ON ImpiegatoIn FOR EACH ROW
BEGIN
    DECLARE v_DataUltManut DATE;
    DECLARE v_DataIntervento DATETIME;

    SELECT DataUltManut INTO v_DataUltManut FROM Mezzo WHERE CodMezzo = NEW.CodMezzo;
    
    SELECT c.OrarioFineChiam INTO v_DataIntervento 
    FROM Intervento i JOIN Chiamata c ON i.CodChiam = c.CodChiam 
    WHERE i.CodInt = NEW.CodInt;

    IF v_DataUltManut < DATE_SUB(DATE(v_DataIntervento), INTERVAL 1 YEAR) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore V7: Revisione mezzo scaduta (oltre 1 anno).';
    END IF;
END $$

DELIMITER ;




############################################################################
################                  VISTE                       ##############
############################################################################

-- 1. Vista per Vigili
CREATE OR REPLACE VIEW Vista_Vigili AS
SELECT CodDip, NomeDip, CognomeDip, Stipendio, CodCaserma, GradoVigile, CodSquad
FROM Dipendente
WHERE GradoVigile IS NOT NULL;

-- 2. Vista per Amministrativi
CREATE OR REPLACE VIEW Vista_Amministrativi AS
SELECT CodDip, NomeDip, CognomeDip, Stipendio, CodCaserma, MansioneAmm, LivFunzionale, AbilitFirma
FROM Dipendente
WHERE MansioneAmm IS NOT NULL;

-- 3. Vista per Centralinisti
CREATE OR REPLACE VIEW Vista_Centralinisti AS
SELECT CodDip, NomeDip, CognomeDip, Stipendio, CodCaserma, AnnoAssunzione, OrarioTurno
FROM Dipendente
WHERE OrarioTurno IS NOT NULL;

-- 4. VISTA per mezzi idonei
CREATE OR REPLACE VIEW Vista_Mezzi_Operativi AS
SELECT CodMezzo, ClasseMezzo, ModelloMezzo, DataUltManut
FROM Mezzo
WHERE DataUltManut >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

-- 5. Report interventi completi
CREATE OR REPLACE VIEW Report_Interventi AS
SELECT 
    i.CodInt, 
    i.TipoInt, 
    i.EsitoInt, 
    i.OraFineInt,
    c.NumChiamante,
    s.DenomOper AS Squadra_Intervenuta
FROM Intervento i
JOIN Chiamata c ON i.CodChiam = c.CodChiam
LEFT JOIN AssegnatoA a ON i.CodInt = a.CodInt
LEFT JOIN Squadra s ON a.CodSquad = s.CodSquad;


-- PROCEDURE 

DELIMITER $$

DROP PROCEDURE IF EXISTS Inserisci_Chiamata $$
CREATE PROCEDURE Inserisci_Chiamata(
    IN p_CodChiam VARCHAR(10),
    IN p_DataInizio DATETIME,
    IN p_DataFine DATETIME,
    IN p_Descr TEXT,
    IN p_NumChiamante VARCHAR(20),
    IN p_CodDip VARCHAR(10)
)
BEGIN
    INSERT INTO Chiamata (CodChiam, OrarioInizioChiam, OrarioFineChiam, DescrChiam, NumChiamante, CodDip)
    VALUES (p_CodChiam, p_DataInizio, p_DataFine, p_Descr, p_NumChiamante, p_CodDip);
END $$


DROP PROCEDURE IF EXISTS Crea_Intervento $$
CREATE PROCEDURE Crea_Intervento(
    IN p_CodInt VARCHAR(10),
    IN p_CodChiam VARCHAR(10),
    IN p_TipoInt VARCHAR(30),
    IN p_Priorita INT,
    IN p_CodSquad VARCHAR(10)
)
BEGIN
    INSERT INTO Intervento (CodInt, TipoInt, PrioritàInt, CodChiam, EsitoInt)
    VALUES (p_CodInt, p_TipoInt, p_Priorita, p_CodChiam, 'In Corso');

    INSERT INTO AssegnatoA (CodSquad, CodInt)
    VALUES (p_CodSquad, p_CodInt);
END $$


DROP PROCEDURE IF EXISTS Verifica_Idoneita_Mezzo $$
CREATE PROCEDURE Verifica_Idoneita_Mezzo(
    IN p_CodMezzo VARCHAR(10),
    OUT p_Idoneo INT
)
BEGIN
    DECLARE v_DataUltManut DATE;
    
    SELECT DataUltManut INTO v_DataUltManut 
    FROM Mezzo 
    WHERE CodMezzo = p_CodMezzo;

    IF v_DataUltManut >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR) THEN
        SET p_Idoneo = 1;
    ELSE
        SET p_Idoneo = 0;
    END IF;
END $$

DROP PROCEDURE IF EXISTS Registra_Manutenzione $$
CREATE PROCEDURE Registra_Manutenzione(
    IN p_CodManut VARCHAR(10),
    IN p_DataSvolg DATE,
    IN p_Spesa DECIMAL(10,2),
    IN p_Tipo VARCHAR(20),
    IN p_Descr TEXT,
    IN p_CodDip VARCHAR(10),
    IN p_DataRichiesta DATE,
    IN p_CodOff VARCHAR(10),
    IN p_CodMezzo VARCHAR(10)
)
BEGIN
    INSERT INTO Manutenzione (CodManut, DataSvolgManut, SpesaManut, TipoManut, DescrManut, CodDip, DataRichiesta, CodOff, CodMezzo)
    VALUES (p_CodManut, p_DataSvolg, p_Spesa, p_Tipo, p_Descr, p_CodDip, p_DataRichiesta, p_CodOff, p_CodMezzo);

    UPDATE Mezzo
    SET DataUltManut = p_DataSvolg
    WHERE CodMezzo = p_CodMezzo
      AND (DataUltManut IS NULL OR DataUltManut < p_DataSvolg);
END $$

DELIMITER ;



-- INTERROGAZIONI 


-- Elenco dei vigili che hanno stipendio sopra la media
SELECT NomeDip, CognomeDip, GradoVigile, Stipendio 
FROM Vista_Vigili 
WHERE Stipendio > (SELECT AVG(Stipendio) FROM Vista_Vigili)
ORDER BY Stipendio DESC;


-- Numero di interventi effettuati da ogni squadra
SELECT s.DenomOper AS Squadra, COUNT(a.CodInt) AS NumeroInterventi
FROM Squadra s
JOIN AssegnatoA a ON s.CodSquad = a.CodSquad
GROUP BY s.DenomOper
ORDER BY NumeroInterventi DESC;


-- Chiamate che non hanno generato interventi (sfruttiamo la left join)
SELECT c.CodChiam, c.OrarioInizioChiam, c.NumChiamante, c.DescrChiam
FROM Chiamata c
LEFT JOIN Intervento i ON c.CodChiam = i.CodChiam
WHERE i.CodInt IS NULL;


-- Trovare chi ha richiesto le manutenzioni più costose, su quale mezzo, quando e quanto è costato.

SELECT 
    man.DataSvolgManut, 
    m.ModelloMezzo, 
    o.NomeOff AS Officina, 
    man.SpesaManut,
    d.CognomeDip AS Richiedente
FROM Manutenzione man
JOIN Mezzo m ON man.CodMezzo = m.CodMezzo
JOIN Officina o ON man.CodOff = o.CodOff
JOIN Dipendente d ON man.CodDip = d.CodDip
WHERE man.SpesaManut > 1000
ORDER BY man.SpesaManut DESC;

-- Filtrare i soli incendi
SELECT Squadra_Intervenuta, EsitoInt, OraFineInt
FROM Report_Interventi
WHERE TipoInt LIKE '%Incendio%'
ORDER BY OraFineInt DESC;
