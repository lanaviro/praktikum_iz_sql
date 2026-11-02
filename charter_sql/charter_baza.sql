USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CharterDB')
BEGIN
    CREATE DATABASE CharterDB;
END
GO

USE CharterDB;
GO

IF OBJECT_ID('dbo.Racun', 'U') IS NOT NULL DROP TABLE dbo.Racun;
IF OBJECT_ID('dbo.Gost', 'U') IS NOT NULL DROP TABLE dbo.Gost;
IF OBJECT_ID('dbo.Kabina', 'U') IS NOT NULL DROP TABLE dbo.Kabina;
IF OBJECT_ID('dbo.Rezervacija', 'U') IS NOT NULL DROP TABLE dbo.Rezervacija;
IF OBJECT_ID('dbo.Brod', 'U') IS NOT NULL DROP TABLE dbo.Brod;
IF OBJECT_ID('dbo.Klijent', 'U') IS NOT NULL DROP TABLE dbo.Klijent;
GO

CREATE TABLE dbo.Klijent (
    OIB_Klijenta    CHAR(11)        NOT NULL,
    Ime             NVARCHAR(50)    NOT NULL,
    Prezime         NVARCHAR(50)    NOT NULL,
    CONSTRAINT PK_Klijent PRIMARY KEY (OIB_Klijenta),
    CONSTRAINT CHK_Klijent_OIB CHECK (OIB_Klijenta NOT LIKE '%[^0-9]%' AND LEN(OIB_Klijenta) = 11)
);
GO

CREATE TABLE dbo.Brod (
    BrodID          INT             NOT NULL IDENTITY(1,1),
    Ime_Broda       NVARCHAR(100)   NOT NULL,
    Destinacija     NVARCHAR(100)   NOT NULL,
    CONSTRAINT PK_Brod PRIMARY KEY (BrodID)
);
GO

CREATE TABLE dbo.Rezervacija (
    Broj_Rezervacije    INT             NOT NULL IDENTITY(1,1),
    Datum_Polaska       DATE            NOT NULL,
    Datum_Odlaska       DATE            NOT NULL,
    Trajanje            AS DATEDIFF(DAY, Datum_Polaska, Datum_Odlaska), -- izracunato automatski
    Zahtjevi            NVARCHAR(500)   NULL,
    Nalaziste           NVARCHAR(100)   NOT NULL,
    OIB_Klijenta        CHAR(11)        NOT NULL,
    CONSTRAINT PK_Rezervacija PRIMARY KEY (Broj_Rezervacije),
    CONSTRAINT FK_Rezervacija_Klijent FOREIGN KEY (OIB_Klijenta)
        REFERENCES dbo.Klijent(OIB_Klijenta),
    CONSTRAINT CHK_Datumi CHECK (Datum_Odlaska > Datum_Polaska)
);
GO

CREATE TABLE dbo.Gost (
    OIB_Gosta           CHAR(11)        NOT NULL,
    Ime                 NVARCHAR(50)    NOT NULL,
    Prezime             NVARCHAR(50)    NOT NULL,
    Broj_Rezervacije    INT             NOT NULL,
    CONSTRAINT PK_Gost PRIMARY KEY (OIB_Gosta),
    CONSTRAINT FK_Gost_Rezervacija FOREIGN KEY (Broj_Rezervacije)
        REFERENCES dbo.Rezervacija(Broj_Rezervacije),
    CONSTRAINT CHK_Gost_OIB CHECK (OIB_Gosta NOT LIKE '%[^0-9]%' AND LEN(OIB_Gosta) = 11)
);
GO

CREATE TABLE dbo.Kabina (
    Broj_Sobe           INT             NOT NULL IDENTITY(1,1),
    Broj_Kreveta        INT             NOT NULL,
    Broj_Kvadrata       DECIMAL(6,2)    NOT NULL,
    Broj_Rezervacije    INT             NULL,   -- NULL jer kabina ne mora uvijek biti rezervirana
    BrodID              INT             NOT NULL,
    CONSTRAINT PK_Kabina PRIMARY KEY (Broj_Sobe),
    CONSTRAINT FK_Kabina_Rezervacija FOREIGN KEY (Broj_Rezervacije)
        REFERENCES dbo.Rezervacija(Broj_Rezervacije),
    CONSTRAINT FK_Kabina_Brod FOREIGN KEY (BrodID)
        REFERENCES dbo.Brod(BrodID),
    CONSTRAINT CHK_Kreveta CHECK (Broj_Kreveta > 0),
    CONSTRAINT CHK_Kvadrata CHECK (Broj_Kvadrata > 0)
);
GO

CREATE TABLE dbo.Racun (
    Broj_Racuna         INT             NOT NULL IDENTITY(1,1),
    Cijena              DECIMAL(10,2)   NOT NULL,
    Popust              DECIMAL(5,2)    NULL DEFAULT 0,
    Nacin_Placanja      NVARCHAR(50)    NOT NULL,
    Broj_Rezervacije    INT             NOT NULL,
    CONSTRAINT PK_Racun PRIMARY KEY (Broj_Racuna),
    CONSTRAINT FK_Racun_Rezervacija FOREIGN KEY (Broj_Rezervacije)
        REFERENCES dbo.Rezervacija(Broj_Rezervacije),
    CONSTRAINT UQ_Racun_Rezervacija UNIQUE (Broj_Rezervacije), -- 1:1 veza
    CONSTRAINT CHK_Cijena CHECK (Cijena >= 0),
    CONSTRAINT CHK_Popust CHECK (Popust >= 0 AND Popust <= 100),
    CONSTRAINT CHK_Nacin_Placanja CHECK (Nacin_Placanja IN ('Gotovina', 'Kartica', 'Transakcijski racun'))
);
GO


INSERT INTO dbo.Klijent VALUES ('12345678901', 'Lana', 'Viro');
INSERT INTO dbo.Klijent VALUES ('98765432109', 'Tomislav', 'Rožić');
GO

INSERT INTO dbo.Brod (Ime_Broda, Destinacija) VALUES ('Pleter', 'Dalmacija');
INSERT INTO dbo.Brod (Ime_Broda, Destinacija) VALUES ('Blues', 'Grčka');
GO

INSERT INTO dbo.Rezervacija (Datum_Polaska, Datum_Odlaska, Zahtjevi, Nalaziste, OIB_Klijenta)
VALUES ('2025-07-01', '2025-07-08', 'Vegetarijanski obrok', 'Split', '12345678901');

INSERT INTO dbo.Rezervacija (Datum_Polaska, Datum_Odlaska, Zahtjevi, Nalaziste, OIB_Klijenta)
VALUES ('2025-08-10', '2025-08-17', NULL, 'Dubrovnik', '98765432109');
GO

-- spremamo u varijable da nemamo problem s IDENTITY brojevima
DECLARE @rez1 INT = (SELECT TOP 1 Broj_Rezervacije FROM dbo.Rezervacija ORDER BY Broj_Rezervacije ASC);
DECLARE @rez2 INT = (SELECT TOP 1 Broj_Rezervacije FROM dbo.Rezervacija ORDER BY Broj_Rezervacije DESC);
DECLARE @brod1 INT = (SELECT TOP 1 BrodID FROM dbo.Brod ORDER BY BrodID ASC);
DECLARE @brod2 INT = (SELECT TOP 1 BrodID FROM dbo.Brod ORDER BY BrodID DESC);

INSERT INTO dbo.Gost VALUES ('11122233344', 'Ana', 'Anić', @rez1);
INSERT INTO dbo.Gost VALUES ('55566677788', 'Pero', 'Perić', @rez1);
INSERT INTO dbo.Gost VALUES ('99988877766', 'Mate', 'Matić', @rez2);

INSERT INTO dbo.Kabina (Broj_Kreveta, Broj_Kvadrata, Broj_Rezervacije, BrodID)
VALUES (2, 18.5, @rez1, @brod1);
INSERT INTO dbo.Kabina (Broj_Kreveta, Broj_Kvadrata, Broj_Rezervacije, BrodID)
VALUES (4, 32.0, @rez1, @brod1);
INSERT INTO dbo.Kabina (Broj_Kreveta, Broj_Kvadrata, Broj_Rezervacije, BrodID)
VALUES (2, 20.0, @rez2, @brod2);

INSERT INTO dbo.Racun (Cijena, Popust, Nacin_Placanja, Broj_Rezervacije)
VALUES (3500.00, 10, 'Kartica', @rez1);
INSERT INTO dbo.Racun (Cijena, Popust, Nacin_Placanja, Broj_Rezervacije)
VALUES (2800.00, 0, 'Gotovina', @rez2);
GO

-- provjera
SELECT 
    r.Broj_Rezervacije,
    k.Ime + ' ' + k.Prezime AS Klijent,
    r.Datum_Polaska,
    r.Datum_Odlaska,
    r.Trajanje,
    r.Nalaziste,
    b.Ime_Broda,
    ra.Cijena,
    ra.Popust,
    ra.Nacin_Placanja
FROM dbo.Rezervacija r
JOIN dbo.Klijent k ON r.OIB_Klijenta = k.OIB_Klijenta
JOIN dbo.Kabina kb ON kb.Broj_Rezervacije = r.Broj_Rezervacije
JOIN dbo.Brod b ON kb.BrodID = b.BrodID
JOIN dbo.Racun ra ON ra.Broj_Rezervacije = r.Broj_Rezervacije;
GO
