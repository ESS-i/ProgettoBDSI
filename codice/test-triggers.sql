############################################################################
################           SCRIPT DI TEST TRIGGER          #################
############################################################################

-- Test: V1 (Orari chiamata)
-- deve fallire perché l'orario di fine (09:59) è precedente all'inizio (10:00)
INSERT INTO Chiamata (CodChiam, OrarioInizioChiam, OrarioFineChiam, DescrChiam, NumChiamante, CodDip)
VALUES ('C_TEST_F', '2025-12-01 10:00:00', '2025-12-01 09:59:00', 'Test Fail', '3339998877', 'D004');

-- ha successo:
INSERT INTO Chiamata (CodChiam, OrarioInizioChiam, OrarioFineChiam, DescrChiam, NumChiamante, CodDip)
VALUES ('C_TEST_S', '2025-12-01 10:00:00', '2025-12-01 10:15:00', 'Test Success', '3339998877', 'D004');


-- Test: V4 (Priorità Intervento)
-- deve fallire perché la priorità (6) è fuori dal range consentito 1-5
INSERT INTO Intervento (CodInt, TipoInt, PrioritàInt, OraFineInt, EsitoInt, CodChiam)
VALUES ('I_TEST_F1', 'Incendio', 6, '2025-12-01 12:00:00', 'In corso', 'CH001');


-- Test: V1 (Orari Intervento)
-- deve fallire perché l'orario di fine intervento (08:00) è precedente alla fine della chiamata CH001 (08:35)
INSERT INTO Intervento (CodInt, TipoInt, PrioritàInt, OraFineInt, EsitoInt, CodChiam)
VALUES ('I_TEST_F2', 'Incendio', 1, '2025-12-01 08:00:00', 'In corso', 'CH001');

-- ha successo:
INSERT INTO Intervento (CodInt, TipoInt, PrioritàInt, OraFineInt, EsitoInt, CodChiam)
VALUES ('I_TEST_S', 'Incendio', 3, '2025-12-01 09:00:00', 'Concluso', 'CH001');

INSERT INTO AssegnatoA (CodSquad, CodInt) VALUES ('SQ01', 'I_TEST_S');


-- Test: V6 (Autorizzazione manutenzione - Ruolo errato)
-- deve fallire perché D001 è un Vigile (MansioneAmm è NULL), non un amministrativo
INSERT INTO Manutenzione (CodManut, DataSvolgManut, SpesaManut, TipoManut, DescrManut, CodDip, DataRichiesta, CodOff, CodMezzo)
VALUES ('M_TEST_F1', '2025-12-28', 500, 'Ordinaria', 'Test Vigile', 'D001', '2025-12-20', 'OFF01', 'VF20100');


-- Test: V6 (Autorizzazione manutenzione - Firma mancante)
-- deve fallire perché D012 è un Amministrativo ma ha AbilitFirma = FALSE
INSERT INTO Manutenzione (CodManut, DataSvolgManut, SpesaManut, TipoManut, DescrManut, CodDip, DataRichiesta, CodOff, CodMezzo)
VALUES ('M_TEST_F2', '2025-12-28', 500, 'Ordinaria', 'Test No Firma', 'D012', '2025-12-20', 'OFF01', 'VF20100');


-- Test: V2 (Date Manutenzione)
-- deve fallire perché la data di svolgimento (01-12) è antecedente alla richiesta (10-12)
INSERT INTO Manutenzione (CodManut, DataSvolgManut, SpesaManut, TipoManut, DescrManut, CodDip, DataRichiesta, CodOff, CodMezzo)
VALUES ('M_TEST_F3', '2025-12-01', 500, 'Ordinaria', 'Test Date', 'D006', '2025-12-10', 'OFF01', 'VF20100');

-- ha successo: (D006 è abilitato e le date sono coerenti)
INSERT INTO Manutenzione (CodManut, DataSvolgManut, SpesaManut, TipoManut, DescrManut, CodDip, DataRichiesta, CodOff, CodMezzo)
VALUES ('M_TEST_S', '2025-12-20', 500, 'Ordinaria', 'Test OK', 'D006', '2025-12-10', 'OFF01', 'VF20100');


-- Test: V4 (Stipendio dipendente)
-- deve fallire perché lo stipendio è negativo
INSERT INTO Dipendente (CodDip, NomeDip, CognomeDip, Stipendio, CodCaserma)
VALUES ('D_TEST_F1', 'Test', 'Negativo', -100, 'CAS01');


-- Test: V3 (Date future fipendente)
-- deve fallire perché l'anno di assunzione (2099) è nel futuro
INSERT INTO Dipendente (CodDip, NomeDip, CognomeDip, Stipendio, AnnoAssunzione, CodCaserma)
VALUES ('D_TEST_F2', 'Test', 'Futuro', 1500, 2099, 'CAS01');

-- ha successo:
INSERT INTO Dipendente (CodDip, NomeDip, CognomeDip, Stipendio, AnnoAssunzione, CodCaserma)
VALUES ('D_TEST_S', 'Test', 'Valido', 1600, 2024, 'CAS01');


-- Test: V7 (Idoneità Mezzo)
INSERT INTO Mezzo (CodMezzo, ClasseMezzo, ModelloMezzo, AnnoFabbMezzo, DataUltManut)
VALUES ('VF_OLD', 'Terrestre', 'Fiat Vecchio', 2010, '2020-01-01');

INSERT INTO Mezzo (CodMezzo, ClasseMezzo, ModelloMezzo, AnnoFabbMezzo, DataUltManut)
VALUES ('VF_NEW', 'Terrestre', 'Fiat Nuovo', 2024, '2025-11-20');

#Creo intervento fittizio
INSERT INTO Intervento (CodInt, TipoInt, PrioritàInt, OraFineInt, EsitoInt, CodChiam)
VALUES ('I_TEST_V7', 'Incendio', 1, '2025-12-01 10:00:00', 'In corso', 'CH001');

INSERT INTO AssegnatoA (CodSquad, CodInt) VALUES ('SQ01', 'I_TEST_V7');

-- deve fallire perché VF_OLD ha la revisione scaduta da oltre un anno rispetto all'intervento (Dic 2025)
INSERT INTO ImpiegatoIn (CodInt, CodMezzo)
VALUES ('I_TEST_V7', 'VF_OLD');

-- ha successo:
INSERT INTO ImpiegatoIn (CodInt, CodMezzo)
VALUES ('I_TEST_V7', 'VF_NEW');