

INSERT INTO Caserma (CodCaserma, CittàCaserma) VALUES ('CAS_TEST', 'Roma');
INSERT INTO Officina (CodOff, NomeOff) VALUES ('OFF_TEST', 'Officina Prova');
INSERT INTO Squadra (CodSquad, CodCaserma) VALUES ('SQ_TEST', 'CAS_TEST');
INSERT INTO Dipendente (CodDip, CodCaserma, CodSquad) VALUES ('DIP_TEST', 'CAS_TEST', 'SQ_TEST');
UPDATE Dipendente 
SET MansioneAmm = 'Responsabile Logistica', AbilitFirma = 1 
WHERE CodDip = 'DIP_TEST';
INSERT INTO Mezzo (CodMezzo, DataUltManut) VALUES ('MEZZO_TEST', '2020-01-01');

-- #############################################################
-- TEST 1: Inserisci_Chiamata
-- #############################################################

CALL Inserisci_Chiamata(
    'CH_TEST',              
    NOW(),                  
    ADDTIME(NOW(), '0:10'), 
    'Incendio sterpaglie', 
    '3331234567',          
    'DIP_TEST'             
);

-- Verifica 
SELECT * FROM Chiamata WHERE CodChiam = 'CH_TEST';

-- #############################################################
-- TEST 2: Crea_Intervento
-- #############################################################

CALL Crea_Intervento(
    'INT_TEST',    
    'CH_TEST',    
    'Incendio',    
    5,             
    'SQ_TEST'      
);

SELECT * FROM Intervento WHERE CodInt = 'INT_TEST';
-- Verifica assegnazione automatica Squadra
SELECT * FROM AssegnatoA WHERE CodInt = 'INT_TEST';

-- #############################################################
-- TEST 3: Registra_Manutenzione
-- #############################################################

CALL Registra_Manutenzione(
    'MAN_TEST',    -- CodManut
    CURDATE(),    
    500.00,        
    'Ordinaria',   -- Tipo
    'Cambio Olio', -- Descrizione
    'DIP_TEST',    -- Richiedente
    CURDATE(),     -- Data Richiesta
    'OFF_TEST',    
    'MEZZO_TEST'    
);

-- Verifica inserimento Manutenzione
SELECT * FROM Manutenzione WHERE CodManut = 'MAN_TEST';

SELECT CodMezzo, DataUltManut FROM Mezzo WHERE CodMezzo = 'MEZZO_TEST';

-- #############################################################
-- TEST 4: Verifica_Idoneita_Mezzo 
-- #############################################################

-- Caso A: Il mezzo è stato appena manutenuto  quindi deve essere idoneo
SET @esito = 0;
CALL Verifica_Idoneita_Mezzo('MEZZO_TEST', @esito);
SELECT 'Test Mezzo Appena Revisionato (Atteso: 1)' AS Descrizione, @esito AS Idoneo;

-- Caso B: Forziamo la data del mezzo al 2020 per simulare scadenza.
UPDATE Mezzo SET DataUltManut = '2020-01-01' WHERE CodMezzo = 'MEZZO_TEST';

SET @esito = 0;
CALL Verifica_Idoneita_Mezzo('MEZZO_TEST', @esito);
SELECT 'Test Mezzo Vecchio (Atteso: 0)' AS Descrizione, @esito AS Idoneo;

-- #############################################################
-- Pulisco tutto dal db
-- #############################################################
DELETE FROM Manutenzione WHERE CodManut = 'MAN_TEST';
DELETE FROM AssegnatoA WHERE CodInt = 'INT_TEST';
DELETE FROM Intervento WHERE CodInt = 'INT_TEST';
DELETE FROM Chiamata WHERE CodChiam = 'CH_TEST';
DELETE FROM Mezzo WHERE CodMezzo = 'MEZZO_TEST';
DELETE FROM Dipendente WHERE CodDip = 'DIP_TEST';
DELETE FROM Squadra WHERE CodSquad = 'SQ_TEST';
DELETE FROM Officina WHERE CodOff = 'OFF_TEST';
DELETE FROM Caserma WHERE CodCaserma = 'CAS_TEST';