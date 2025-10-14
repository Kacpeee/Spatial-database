-- 1. Utworzenie bazy danych
CREATE DATABASE firma;
GO

-- 2. U�ycie bazy
USE firma;
GO

-- 3. Utworzenie schematu
CREATE SCHEMA ksiegowosc;
GO

-- 4. Tworzenie tabel

-- Tabela pracownicy
CREATE TABLE ksiegowosc.pracownicy (
    id_pracownika INT IDENTITY(1,1) PRIMARY KEY,
    imie NVARCHAR(50) NOT NULL,
    nazwisko NVARCHAR(50) NOT NULL,
    adres NVARCHAR(100),
    telefon NVARCHAR(20)
);
EXEC sp_addextendedproperty 'MS_Description', 'Tabela przechowuje dane pracownik�w.', 'SCHEMA', 'ksiegowosc', 'TABLE', 'pracownicy';
GO

-- Tabela godziny
CREATE TABLE ksiegowosc.godziny (
    id_godziny INT IDENTITY(1,1) PRIMARY KEY,
    data DATE NOT NULL,
    liczba_godzin DECIMAL(5,2) NOT NULL,
    id_pracownika INT NOT NULL,
    FOREIGN KEY (id_pracownika) REFERENCES ksiegowosc.pracownicy(id_pracownika)
);
EXEC sp_addextendedproperty 'MS_Description', 'Tabela ewidencjonuje przepracowane godziny pracownik�w.', 'SCHEMA', 'ksiegowosc', 'TABLE', 'godziny';
GO

-- Tabela pensja
CREATE TABLE ksiegowosc.pensja (
    id_pensji INT IDENTITY(1,1) PRIMARY KEY,
    stanowisko NVARCHAR(50) NOT NULL,
    kwota DECIMAL(10,2) NOT NULL
);
EXEC sp_addextendedproperty 'MS_Description', 'Tabela zawiera dane o stanowiskach i pensjach.', 'SCHEMA', 'ksiegowosc', 'TABLE', 'pensja';
GO

-- Tabela premia
CREATE TABLE ksiegowosc.premia (
    id_premii INT IDENTITY(1,1) PRIMARY KEY,
    rodzaj NVARCHAR(50),
    kwota DECIMAL(10,2)
);
EXEC sp_addextendedproperty 'MS_Description', 'Tabela przechowuje informacje o przyznanych premiach.', 'SCHEMA', 'ksiegowosc', 'TABLE', 'premia';
GO

-- Tabela wynagrodzenie
CREATE TABLE ksiegowosc.wynagrodzenie (
    id_wynagrodzenia INT IDENTITY(1,1) PRIMARY KEY,
    data DATE NOT NULL,
    id_pracownika INT NOT NULL,
    id_godziny INT NOT NULL,
    id_pensji INT NOT NULL,
    id_premii INT NULL,
    FOREIGN KEY (id_pracownika) REFERENCES ksiegowosc.pracownicy(id_pracownika),
    FOREIGN KEY (id_godziny) REFERENCES ksiegowosc.godziny(id_godziny),
    FOREIGN KEY (id_pensji) REFERENCES ksiegowosc.pensja(id_pensji),
    FOREIGN KEY (id_premii) REFERENCES ksiegowosc.premia(id_premii)
);
EXEC sp_addextendedproperty 'MS_Description', 'Tabela ��czy informacje o p�acach, godzinach i premiach.', 'SCHEMA', 'ksiegowosc', 'TABLE', 'wynagrodzenie';
GO


-- 5. Wstawienie przyk�adowych danych (po 10 rekord�w)

INSERT INTO ksiegowosc.pracownicy (imie, nazwisko, adres, telefon) VALUES
('Jan','Kowalski','ul. S�oneczna 1','600100100'),
('Anna','Nowak','ul. Le�na 2','600200200'),
('Jakub','Wi�niewski','ul. Ogrodowa 3','600300300'),
('Julia','Lewandowska','ul. Polna 4','600400400'),
('Micha�','Zieli�ski','ul. D�uga 5','600500500'),
('Katarzyna','Kami�ska','ul. Kr�tka 6','600600600'),
('Jacek','Kowalczyk','ul. Jasna 7','600700700'),
('Joanna','Szyma�ska','ul. Parkowa 8','600800800'),
('Pawe�','Duda','ul. Mickiewicza 9','600900900'),
('Magdalena','Nowicka','ul. Lipowa 10','601000100');
GO

INSERT INTO ksiegowosc.pensja (stanowisko, kwota) VALUES
('Kierownik',5000),
('Asystent',2000),
('Programista',3000),
('Ksi�gowy',2500),
('Sekretarka',1800),
('Sprzedawca',1500),
('Mened�er',4000),
('Technik',2200),
('Analityk',2800),
('Referent',2100);
GO

INSERT INTO ksiegowosc.premia (rodzaj, kwota) VALUES
('Roczna',1000),
('Miesi�czna',500),
('Projektowa',800),
('Motywacyjna',600),
('Specjalna',700),
('Lojalno�ciowa',400),
('Bonus',300),
('Za wyniki',900),
('�wi�teczna',500),
('Awansowa',1000);
GO

INSERT INTO ksiegowosc.godziny (data, liczba_godzin, id_pracownika) VALUES
('2025-01-01',160,1),
('2025-01-01',170,2),
('2025-01-01',150,3),
('2025-01-01',180,4),
('2025-01-01',160,5),
('2025-01-01',155,6),
('2025-01-01',165,7),
('2025-01-01',160,8),
('2025-01-01',170,9),
('2025-01-01',160,10);
GO

INSERT INTO ksiegowosc.wynagrodzenie (data, id_pracownika, id_godziny, id_pensji, id_premii) VALUES
('2025-01-31',1,1,1,1),
('2025-01-31',2,2,2,2),
('2025-01-31',3,3,3,3),
('2025-01-31',4,4,4,4),
('2025-01-31',5,5,5,5),
('2025-01-31',6,6,6,6),
('2025-01-31',7,7,7,7),
('2025-01-31',8,8,8,8),
('2025-01-31',9,9,9,9),
('2025-01-31',10,10,10,10);
GO
