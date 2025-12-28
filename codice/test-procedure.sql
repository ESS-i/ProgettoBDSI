-- #############################################################
-- PREPARAZIONE DATI DI TEST (Per evitare errori di Chiave Esterna)
-- #############################################################

INSERT INTO Caserma (CodCaserma, CittàCaserma) VALUES ('CAS_TEST', 'Roma');
INSERT INTO Officina (CodOff, NomeOff) VALUES ('OFF_TEST', 'Officina Prova');
INSERT INTO Squadra (CodSquad, CodCaserma) VALUES ('SQ_TEST', 'CAS_TEST');
INSERT INTO Dipendente (CodDip, CodCaserma, CodSquad) VALUES ('DIP_TEST', 'CAS_TEST', 'SQ_TEST');
UPDATE Dipendente 
SET MansioneAmm = 'Responsabile Logistica', AbilitFirma = 1 
WHERE CodDip = 'DIP_TEST';
INSERT INTO Mezzo (CodMezzo, DataUltManut) VALUES ('MEZZO_TEST', '2020-01-01');

-- #############################################################
-- TEST 1: Inserisci_Chiamata (Operazione O1)
-- #############################################################

-- Inseriamo una chiamata con ID 'CH_TEST'
CALL Inserisci_Chiamata(
    'CH_TEST',              -- CodChiam
    NOW(),                  -- Inizio (Adesso)
    ADDTIME(NOW(), '0:10'), -- Fine (Tra 10 min)
    'Incendio sterpaglie',  -- Descrizione
    '3331234567',           -- Numero
    'DIP_TEST'              -- Dipendente
);

-- Verifica inserimento
SELECT * FROM Chiamata WHERE CodChiam = 'CH_TEST';

-- #############################################################
-- TEST 2: Crea_Intervento (Operazione O2)
-- #############################################################

-- Creiamo un intervento 'INT_TEST' generato dalla chiamata 'CH_TEST'
CALL Crea_Intervento(
    'INT_TEST',    -- CodInt
    'CH_TEST',     -- CodChiam (generatore)
    'Incendio',    -- Tipo
    5,             -- Priorità
    'SQ_TEST'      -- Squadra assegnata
);

-- Verifica creazione Intervento
SELECT * FROM Intervento WHERE CodInt = 'INT_TEST';
-- Verifica assegnazione automatica Squadra
SELECT * FROM AssegnatoA WHERE CodInt = 'INT_TEST';

-- #############################################################
-- TEST 3: Registra_Manutenzione (Operazione O4)
-- #############################################################

-- Nota: Prima del test, il MEZZO_TEST ha data manutenzione '2020-01-01'.
-- Inseriamo una nuova manutenzione svolta OGGI.

CALL Registra_Manutenzione(
    'MAN_TEST',    -- CodManut
    CURDATE(),     -- DataSvolg (Oggi)
    500.00,        -- Spesa
    'Ordinaria',   -- Tipo
    'Cambio Olio', -- Descrizione
    'DIP_TEST',    -- Richiedente
    CURDATE(),     -- Data Richiesta
    'OFF_TEST',    -- Officina
    'MEZZO_TEST'   -- Mezzo
);

-- Verifica inserimento Manutenzione
SELECT * FROM Manutenzione WHERE CodManut = 'MAN_TEST';

-- Verifica AGGIORNAMENTO RIDONDANZA su Mezzo (Deve essere la data di oggi)
SELECT CodMezzo, DataUltManut FROM Mezzo WHERE CodMezzo = 'MEZZO_TEST';

-- #############################################################
-- TEST 4: Verifica_Idoneita_Mezzo (Operazione O3)
-- #############################################################

-- Caso A: Il mezzo è stato appena manutenuto (Test 3), quindi DEVE essere idoneo (1).
SET @esito = 0;
CALL Verifica_Idoneita_Mezzo('MEZZO_TEST', @esito);
SELECT 'Test Mezzo Appena Revisionato (Atteso: 1)' AS Descrizione, @esito AS Idoneo;

-- Caso B: Forziamo la data del mezzo al 2020 per simulare scadenza.
UPDATE Mezzo SET DataUltManut = '2020-01-01' WHERE CodMezzo = 'MEZZO_TEST';

SET @esito = 0;
CALL Verifica_Idoneita_Mezzo('MEZZO_TEST', @esito);
SELECT 'Test Mezzo Vecchio (Atteso: 0)' AS Descrizione, @esito AS Idoneo;

-- #############################################################
-- PULIZIA DATI DI TEST
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