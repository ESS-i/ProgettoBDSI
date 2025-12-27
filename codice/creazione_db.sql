#################### CREAZIONE DATABASE ####################

DROP DATABASE IF EXISTS VigiliDelFuoco;
CREATE DATABASE VigiliDelFuoco;
USE VigiliDelFuoco;

#################### CREAZIONE TABELLE ####################

CREATE TABLE Caserma (
    CodCaserma VARCHAR(10) PRIMARY KEY,
    NumTelCaserma VARCHAR(20),
    ViaCaserma VARCHAR(50),
    CivicoCaserma VARCHAR(10),
    CapCaserma VARCHAR(10),
    CittàCaserma VARCHAR(50)
);

CREATE TABLE Officina (
    CodOff VARCHAR(10) PRIMARY KEY,
    TelOff VARCHAR(20),
    NomeOff VARCHAR(50),
    CittàOff VARCHAR(50),
    ViaOff VARCHAR(50),
    CivicoOff VARCHAR(10),
    CapOff VARCHAR(10)
);

CREATE TABLE Convenzione (
    CodCaserma VARCHAR(10),
    CodOff VARCHAR(10),
    PRIMARY KEY (CodCaserma, CodOff),
    FOREIGN KEY (CodCaserma) REFERENCES Caserma(CodCaserma) ON UPDATE CASCADE,
    FOREIGN KEY (CodOff) REFERENCES Officina(CodOff) ON UPDATE CASCADE
);

CREATE TABLE Squadra (
    CodSquad VARCHAR(10) PRIMARY KEY,
    DenomOper VARCHAR(50),
    AreaComp VARCHAR(50),
    DataCostit DATE,
    CodCaserma VARCHAR(10),
    FOREIGN KEY (CodCaserma) REFERENCES Caserma(CodCaserma) ON UPDATE CASCADE
);

CREATE TABLE Dipendente (
    CodDip VARCHAR(10) PRIMARY KEY,
    NomeDip VARCHAR(50),
    CognomeDip VARCHAR(50),
    Stipendio DECIMAL(10,2),
    GradoVigile VARCHAR(30),
    AnnoAssunzione INT,
    OrarioTurno VARCHAR(20),
    MansioneAmm VARCHAR(50),
    LivFunzionale VARCHAR(20),
    AbilitFirma BOOLEAN,
    CodSquad VARCHAR(10),
    DataEntrata DATE,
    DataUscita DATE,
    CodCaserma VARCHAR(10),
    FOREIGN KEY (CodSquad) REFERENCES Squadra(CodSquad) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (CodCaserma) REFERENCES Caserma(CodCaserma) ON UPDATE CASCADE
);

CREATE TABLE Mezzo (
    CodMezzo VARCHAR(10) PRIMARY KEY,
    ClasseMezzo VARCHAR(20),
    ModelloMezzo VARCHAR(50),
    AnnoFabbMezzo INT,
    DataUltManut DATE
);

CREATE TABLE Chiamata (
    CodChiam VARCHAR(10) PRIMARY KEY,
    OrarioInizioChiam DATETIME,
    OrarioFineChiam DATETIME,
    DescrChiam TEXT,
    NumChiamante VARCHAR(20),
    CodDip VARCHAR(10),
    FOREIGN KEY (CodDip) REFERENCES Dipendente(CodDip) ON UPDATE CASCADE
);

CREATE TABLE Intervento (
    CodInt VARCHAR(10) PRIMARY KEY,
    TipoInt VARCHAR(30),
    PrioritàInt INT,
    OraFineInt DATETIME,
    EsitoInt VARCHAR(50),
    CodChiam VARCHAR(10),
    FOREIGN KEY (CodChiam) REFERENCES Chiamata(CodChiam) ON UPDATE CASCADE
);

CREATE TABLE AssegnatoA (
    CodSquad VARCHAR(10),
    CodInt VARCHAR(10),
    PRIMARY KEY (CodSquad, CodInt),
    FOREIGN KEY (CodSquad) REFERENCES Squadra(CodSquad) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CodInt) REFERENCES Intervento(CodInt) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ImpiegatoIn (
    CodInt VARCHAR(10),
    CodMezzo VARCHAR(10),
    PRIMARY KEY (CodInt, CodMezzo),
    FOREIGN KEY (CodInt) REFERENCES Intervento(CodInt) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CodMezzo) REFERENCES Mezzo(CodMezzo) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Manutenzione (
    CodManut VARCHAR(10) PRIMARY KEY,
    DataSvolgManut DATE,
    SpesaManut DECIMAL(10,2),
    TipoManut VARCHAR(20),
    DescrManut TEXT,
    CodDip VARCHAR(10),
    DataRichiesta DATE,
    CodOff VARCHAR(10),
    CodMezzo VARCHAR(10),
    FOREIGN KEY (CodDip) REFERENCES Dipendente(CodDip) ON UPDATE CASCADE,
    FOREIGN KEY (CodOff) REFERENCES Officina(CodOff) ON UPDATE CASCADE,
    FOREIGN KEY (CodMezzo) REFERENCES Mezzo(CodMezzo) ON UPDATE CASCADE
);

#################### IMPORTAZIONE DEI DATI ####################

LOAD DATA LOCAL INFILE 'dati/caserma.txt' 
INTO TABLE Caserma 
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '|' IGNORE 4 LINES;

LOAD DATA LOCAL INFILE 'dati/officina.csv' 
INTO TABLE Officina 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/convenzione.csv' 
INTO TABLE Convenzione 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/squadra.csv' 
INTO TABLE Squadra 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Dipendente (CSV corretto a 14 colonne)
LOAD DATA LOCAL INFILE 'dati/dipendente.csv' 
INTO TABLE Dipendente 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(CodDip, NomeDip, CognomeDip, Stipendio, @GradoVigile, @AnnoAssunzione, @OrarioTurno, @MansioneAmm, @LivFunzionale, @AbilitFirma, @CodSquad, @DataEntrata, @DataUscita, CodCaserma)
SET 
GradoVigile = NULLIF(@GradoVigile, ''),
AnnoAssunzione = NULLIF(@AnnoAssunzione, ''),
OrarioTurno = NULLIF(@OrarioTurno, ''),
MansioneAmm = NULLIF(@MansioneAmm, ''),
LivFunzionale = NULLIF(@LivFunzionale, ''),
AbilitFirma = (@AbilitFirma = 'TRUE'), 
CodSquad = NULLIF(@CodSquad, ''),
DataEntrata = NULLIF(@DataEntrata, ''),
DataUscita = NULLIF(@DataUscita, '');

LOAD DATA LOCAL INFILE 'dati/mezzo.csv' 
INTO TABLE Mezzo 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(CodMezzo, ClasseMezzo, ModelloMezzo, AnnoFabbMezzo, @DataUltManut)
SET DataUltManut = NULLIF(@DataUltManut, '');

LOAD DATA LOCAL INFILE 'dati/chiamata.csv' 
INTO TABLE Chiamata 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/intervento.csv' 
INTO TABLE Intervento 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/assegnatoa.csv' 
INTO TABLE AssegnatoA 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/impiegatoin.csv' 
INTO TABLE ImpiegatoIn 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'dati/manutenzione.csv' 
INTO TABLE Manutenzione 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
