
CREATE TABLE Role (
    id_roli INT AUTO_INCREMENT PRIMARY KEY,
    nazwa_roli VARCHAR(50) NOT NULL
);



CREATE TABLE Uzytkownicy (
    id_uzytkownika INT AUTO_INCREMENT PRIMARY KEY,
    nazwa_uzytkownika VARCHAR(50) NOT NULL,
    haslo VARCHAR(255) NOT NULL,
    id_roli INT NOT NULL,
    FOREIGN KEY (id_roli) REFERENCES Role(id_roli)
);




ORDER BY id_polaczenia  Desc
CREATE TABLE Klienci (
    id_klienta INT AUTO_INCREMENT PRIMARY KEY,
    imie VARCHAR(50) NOT NULL,
    nazwisko VARCHAR(50) NOT NULL,
    numer_telefonu VARCHAR(30) NOT NULL,
    email VARCHAR(100)
);



CREATE TABLE RodzajeOgrzewania (
    id_ogrzewania INT AUTO_INCREMENT PRIMARY KEY,
    typ_ogrzewania VARCHAR(50) NOT NULL
);



CREATE TABLE Izolacje (
    id_izolacji INT AUTO_INCREMENT PRIMARY KEY,
    ocieplenie_dachu VARCHAR(50) NOT NULL,
    ocieplenie_scian VARCHAR(50) NOT NULL,
    okna ENUM('Drewniane', 'Plastikowe') NOT NULL
);


CREATE TABLE Kampanie (
    id_kampanii INT AUTO_INCREMENT PRIMARY KEY,
    nazwa_kampanii VARCHAR(100) NOT NULL,
    data_rozpoczecia DATE NOT NULL,
    data_zakonczenia DATE,
    id_menedzera INT NOT NULL,
    FOREIGN KEY (id_menedzera) REFERENCES Uzytkownicy(id_uzytkownika)
);


CREATE TABLE Polaczenia (
    id_polaczenia INT AUTO_INCREMENT PRIMARY KEY,
    id_uzytkownika INT NOT NULL,
    id_klienta INT NOT NULL,
    id_kampanii INT,
    data_polaczenia DATETIME NOT NULL,
    czas_trwania INT NOT NULL,
    FOREIGN KEY (id_uzytkownika) REFERENCES Uzytkownicy(id_uzytkownika),
    FOREIGN KEY (id_klienta) REFERENCES Klienci(id_klienta),
    FOREIGN KEY (id_kampanii) REFERENCES Kampanie(id_kampanii)
);



CREATE TABLE Umowy (
    id_umowy INT AUTO_INCREMENT PRIMARY KEY, 
    id_polaczenia INT NOT NULL,
    id_uzytkownika INT NOT NULL,
    id_operatora INT,
    id_klienta INT NOT NULL,
    status VARCHAR(50),
    data_umowy DATE NOT NULL,
    data_ukonczenia DATE NOT NULL,
    FOREIGN KEY (id_polaczenia) REFERENCES Polaczenia(id_polaczenia),
    FOREIGN KEY (id_uzytkownika) REFERENCES Uzytkownicy(id_uzytkownika),
    FOREIGN KEY (id_klienta) REFERENCES Klienci(id_klienta)
);


CREATE TABLE Adresy (
    id_adresu INT AUTO_INCREMENT PRIMARY KEY,
    ulica VARCHAR(100) NOT NULL,
    numer_domu VARCHAR(10) NOT NULL,
    numer_mieszkania VARCHAR(10),
    miasto VARCHAR(50) NOT NULL,
    kod_pocztowy VARCHAR(10) NOT NULL,
    id_polaczenia int NOT NULL,
    czyste_powietrze ENUM('Tak', 'Nie', "W trakcie", "Brak informacji") NOT NULL,
    FOREIGN KEY (id_polaczenia) REFERENCES Polaczenia(id_polaczenia)

    

 CREATE TABLE LogiDostepu (
    id_logu INT AUTO_INCREMENT PRIMARY KEY,
    id_uzytkownika INT NOT NULL,
    id_kampanii INT,
    czas_przerwy int,
    czas_logowania DATETIME NOT NULL,
    czas_wylogowania DATETIME,
    FOREIGN KEY (id_uzytkownika) REFERENCES Uzytkownicy(id_uzytkownika),
    FOREIGN KEY (id_kampanii) REFERENCES Kampanie(id_kampanii)
);




CREATE TABLE Platnosci (
    id_platnosci INT AUTO_INCREMENT PRIMARY KEY,
    id_umowy INT NOT NULL,
    kwota DECIMAL(10,2) NOT NULL,
    data_platnosci DATE NOT NULL,
    FOREIGN KEY (id_umowy) REFERENCES Umowy(id_umowy)
);




CREATE TABLE Ankiety (
    id_ankiety INT AUTO_INCREMENT PRIMARY KEY,
    id_polaczenia INT NOT NULL,
    ocena INT NOT NULL CHECK (ocena BETWEEN 1 AND 5),
    komentarze TEXT,
    FOREIGN KEY (id_polaczenia) REFERENCES Polaczenia(id_polaczenia)
);



CREATE TABLE Obiekcje (
  	id_obiekcji INT AUTO_INCREMENT PRIMARY KEY,
	tresc_obiekcji VARCHAR(50)
);






CREATE OR REPLACE TABLE ObiekcjeDzialaniaPoPolaczeniu (
    id_dzialania INT AUTO_INCREMENT PRIMARY KEY,
    id_polaczenia INT NOT NULL,
    id_uzytkownika INT NOT NULL,
    data_dzialania DATE NOT NULL,
    status ENUM('1', '0') NOT NULL,
    id_obiekcji INT NOT NULL,
    call_back DATETIME,
    FOREIGN KEY (id_polaczenia) REFERENCES Polaczenia(id_polaczenia),
    FOREIGN KEY (id_uzytkownika) REFERENCES Uzytkownicy(id_uzytkownika),
    FOREIGN KEY (id_obiekcji) REFERENCES Obiekcje(id_obiekcji)
);





CREATE TABLE Wojewodztwa (
    id_wojewodztwa INT AUTO_INCREMENT PRIMARY KEY,
    nazwa_wojewodztwa VARCHAR(50) NOT NULL
);





CREATE PROCEDURE PobierzIdIzolacji(
    IN input_ocieplenie_dachu VARCHAR(255),
    IN input_ocieplenie_scian VARCHAR(255),
    IN input_okna VARCHAR(255),
    OUT output_id_izolacji INT
)
BEGIN
    SELECT id_izolacji
    INTO output_id_izolacji
    FROM Izolacje
    WHERE ocieplenie_dachu = input_ocieplenie_dachu
      AND ocieplenie_scian = input_ocieplenie_scian
      AND okna = input_okna;


    IF output_id_izolacji IS NULL THEN
        SET output_id_izolacji = -1; 
    END IF;
END





CREATE OR REPLACE PROCEDURE PobierzIdOgrzewania(
    IN input_typ_ogrzewania VARCHAR(255),
    OUT output_id_ogrzewania INT
)
BEGIN
    SELECT id_ogrzewania
    INTO output_id_ogrzewania
    FROM RodzajeOgrzewania
    WHERE typ_ogrzewania = input_typ_ogrzewania;

  
    IF output_id_ogrzewania IS NULL THEN
        SET output_id_ogrzewania = -1; 
    END IF;
END




CREATE PROCEDURE DodajSzczegolyKlienta(IN p_id_polaczenia INT)
BEGIN
    DECLARE v_id_klienta INT;
    DECLARE v_id_adresu INT;

    SELECT id_klienta INTO v_id_klienta
    FROM Polaczenia
    WHERE id_polaczenia = p_id_polaczenia;

    SELECT id_adresu INTO v_id_adresu
    FROM Adresy
    WHERE id_polaczenia = p_id_polaczenia
    LIMIT 1;

    INSERT INTO SzczegolyKlienta (id_polaczenia, id_klienta, id_adresu)
    VALUES (p_id_polaczenia, v_id_klienta, v_id_adresu);
END





CREATE OR REPLACE PROCEDURE PobierzIdIzolacji(
    IN dach VARCHAR(255),
    IN sciany VARCHAR(255),
    IN okna VARCHAR(255),
    OUT id_izolacji INT
)
BEGIN
    DECLARE existing_id INT DEFAULT NULL;
    
    SELECT id_izolacji INTO existing_id 
    FROM Izolacje 
    WHERE 
        ocieplenie_dachu = dach AND 
        ocieplenie_scian = sciany AND 
        okna = okna 
    LIMIT 1; 
    IF existing_id IS NULL THEN
        INSERT INTO Izolacje (ocieplenie_dachu, ocieplenie_scian, okna)
        VALUES (dach, sciany, okna);
        SET id_izolacji = LAST_INSERT_ID();
    ELSE
        SET id_izolacji = existing_id;
    END IF;
END





CREATE OR REPLACE PROCEDURE UpdateStatusUmowy()
BEGIN
    DECLARE v_total INT;
    DECLARE v_limit INT;
    
    SET @DISABLE_TRIGGERS = TRUE;
    
    SELECT COUNT(*) INTO v_total 
    FROM Umowy 
    WHERE status IS NULL;
    
    SET v_limit = GREATEST(1, FLOOR(v_total * 0.3));
    
    UPDATE Umowy u
    JOIN (
        SELECT id_umowy 
        FROM Umowy 
        WHERE status IS NULL 
        ORDER BY RAND() 
        LIMIT v_limit
    ) AS tmp ON u.id_umowy = tmp.id_umowy
    SET 
        u.status = CASE 
            WHEN RAND() < 0.9 THEN 1  -- 90% szans na 1
            ELSE 0                     -- 10% szans na 0
        END;
        
    SET @DISABLE_TRIGGERS = FALSE;
END







CREATE OR REPLACE PROCEDURE WylosujKlienta()
BEGIN
    DECLARE random_id INT;
    
    SELECT id_klienta INTO random_id
    FROM Klienci
    WHERE customer_call = 0
    ORDER BY RAND()
    LIMIT 1;
    
    SELECT random_id;
END 

CREATE OR REPLACE PROCEDURE DodajSzczegolyKlienta(
    IN p_id_polaczenia INT,
    IN p_id_klienta INT
)
BEGIN
    DECLARE v_id_adresu INT;

    SELECT id_adresu INTO v_id_adresu
    FROM Adresy
    WHERE id_klienta = p_id_klienta
    ORDER BY id_adresu DESC
    LIMIT 1;

    INSERT INTO SzczegolyKlienta (id_polaczenia, id_klienta, id_adresu)
    VALUES (p_id_polaczenia, p_id_klienta, v_id_adresu);
END







CREATE OR REPLACE PROCEDURE daily_random_success()
BEGIN
    DECLARE v_limit INT;
    
    SELECT 
        CASE 
            WHEN COUNT(*) * 0.3 < 1 THEN 1 
            ELSE FLOOR(COUNT(*) * 0.3) 
        END 
    INTO v_limit 
    FROM SzczegolyKlienta 
    WHERE sukces IS NULL;

    
    
    
CREATE TRIGGER UpdateCustomerCallAfterInsert
AFTER INSERT ON Polaczenia
FOR EACH ROW
BEGIN

    IF EXISTS (SELECT 1 FROM Klienci WHERE id_klienta = NEW.id_klienta) THEN
      
        UPDATE Klienci
        SET customer_call = 1
        WHERE id_klienta = NEW.id_klienta;
    END IF;
END





CREATE OR REPLACE TRIGGER after_insert_polaczenia
AFTER INSERT ON Polaczenia
FOR EACH ROW
BEGIN
  
    IF NEW.sukces = 1 THEN
      
        CALL DodajSzczegolyKlienta(NEW.id_polaczenia);
    END IF;
END






CREATE TRIGGER before_insert_adresy
BEFORE INSERT ON Adresy
FOR EACH ROW
BEGIN

    SET NEW.nazwa_wojewodztwa = (
        SELECT nazwa_wojewodztwa
        FROM Wojewodztwa
        WHERE id_wojewodztwa = NEW.id_wojewodztwa
        LIMIT 1
    );


    SET NEW.id_polaczenia = (
        SELECT id_polaczenia
        FROM Polaczenia
        WHERE id_klienta = NEW.id_klienta
        ORDER BY id_polaczenia DESC
        LIMIT 1
    );
END







CREATE OR REPLACE TRIGGER after_update_polaczenia
AFTER UPDATE ON Polaczenia
FOR EACH ROW
BEGIN
    DECLARE v_id_adresu INT;

    IF NEW.sukces = 1 AND (OLD.sukces IS NULL OR OLD.sukces != 1) THEN
        SELECT id_adresu INTO v_id_adresu
        FROM Adresy
        WHERE id_klienta = NEW.id_klienta
        ORDER BY id_adresu DESC
        LIMIT 1;

        IF v_id_adresu IS NOT NULL THEN
            INSERT INTO SzczegolyKlienta (id_polaczenia, id_klienta, id_adresu)
            VALUES (NEW.id_polaczenia, NEW.id_klienta, v_id_adresu);
        END IF;
    END IF;
END






CREATE TRIGGER oblicz_czas_sesji_format
BEFORE UPDATE ON LogiDostepu
FOR EACH ROW
BEGIN
    IF NEW.czas_wylogowania IS NOT NULL AND OLD.czas_wylogowania IS NULL THEN
        SET NEW.czas_sesji = TIMEDIFF(NEW.czas_wylogowania, OLD.czas_logowania);
    END IF;
END;





CREATE OR REPLACE TRIGGER aktualizuj_umowy_po_sukcesie 
AFTER UPDATE ON SzczegolyKlienta
FOR EACH ROW
BEGIN
    DECLARE v_id_adresu INT;
    DECLARE v_id_wojewodztwa INT;
    DECLARE v_id_operatora INT;

    IF NEW.sukces = 1 AND (OLD.sukces IS NULL OR OLD.sukces != 1) THEN
        SET v_id_adresu = NEW.id_adresu;
        
        SELECT id_wojewodztwa INTO v_id_wojewodztwa 
        FROM Adresy 
        WHERE id_adresu = v_id_adresu;
        
        SELECT id_operatora INTO v_id_operatora 
        FROM Wojewodztwa 
        WHERE id_wojewodztwa = v_id_wojewodztwa;

        INSERT INTO Umowy (data_umowy, id_szczegolu, id_operatora)
        VALUES (CURDATE(), NEW.id_szczegolu, v_id_operatora);
    END IF;
END





CREATE OR REPLACE TRIGGER generuj_platnosc_po_sukcesie 
AFTER UPDATE ON Umowy
FOR EACH ROW
BEGIN
    IF NEW.status = 1 AND (OLD.status!= 1 OR OLD.status IS NULL) THEN
        INSERT INTO Platnosci (id_umowy, kwota, data_platnosci)
        VALUES (
            NEW.id_umowy,
            FLOOR(10000 + (RAND() * 110000)), 
            CURDATE()
        );
    END IF;
END





CREATE TRIGGER after_umowy_status_update 
BEFORE UPDATE ON Umowy
FOR EACH ROW
BEGIN
    IF NEW.status = 1 AND (OLD.status IS NULL OR OLD.status != 1) THEN
        SET NEW.data_ukonczenia = CURDATE();
    END IF;




CREATE OR REPLACE TRIGGER after_umowy_status_update_ankiety
AFTER UPDATE ON Umowy
FOR EACH ROW
BEGIN
    DECLARE v_id_polaczenia INT;
    DECLARE v_id_kampanii INT;
    DECLARE v_id_uzytkownika INT;

    IF NEW.status = 1 THEN
        
        SELECT id_polaczenia INTO v_id_polaczenia
        FROM SzczegolyKlienta
        WHERE id_szczegolu = NEW.id_szczegolu;

       
        SELECT id_kampanii, id_uzytkownika
        INTO v_id_kampanii, v_id_uzytkownika
        FROM Polaczenia
        WHERE id_polaczenia = v_id_polaczenia;

        
        INSERT INTO Ankiety (
            id_kampanii,
            id_uzytkownika,
            id_polaczenia,
            ocena
        ) VALUES (
            v_id_kampanii,
            v_id_uzytkownika,
            v_id_polaczenia,
            FLOOR(RAND() * 5) + 1 
        );
    END IF;
END




CREATE OR REPLACE EVENT daily_umowy_update
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP   
DO
    CALL daily_update_umowy(); 

    
    
    
    
CREATE OR REPLACE EVENT test_success_randomizer
ON SCHEDULE EVERY 1 DAY
DO
    CALL daily_random_success()


SET GLOBAL event_scheduler=ON




CREATE OR REPLACE VIEW Widok_Efektywnosci_Kampanii AS
SELECT 
  k.nazwa_kampanii,
  CONCAT(m.imie, ' ', m.nazwisko) AS menadzer,
  COUNT(p.id_polaczenia) AS liczba_polaczen,
  Round(AVG(p.czas_trwania),2) AS sredni_czas_rozmowy,
  SUM(p.sukces) AS sukcesy,
  AVG(a.ocena) AS srednia_ocena_ankiety,
  Round(AVG(pl.kwota),2) AS srednia_platnosc
FROM Kampanie k
LEFT JOIN Polaczenia p ON k.id_kampanii = p.id_kampanii
LEFT JOIN Ankiety a ON p.id_polaczenia = a.id_polaczenia
LEFT JOIN SzczegolyKlienta s ON p.id_polaczenia = s.id_polaczenia
LEFT JOIN Umowy u ON s.id_szczegolu = u.id_szczegolu
LEFT JOIN Platnosci pl ON u.id_umowy = pl.id_umowy
LEFT JOIN Uzytkownicy m ON 
  k.id_menedzera = m.id_uzytkownika 
  AND m.id_roli = 1  -- Filtruj tylko użytkowników z rolą menedżera
GROUP BY k.id_kampanii;



CREATE VIEW Widok_Szczegolow_Klienta AS
SELECT 
  s.id_szczegolu,
  CONCAT(m.imie, ' ', m.nazwisko) AS klient,
  ro.typ_ogrzewania,
  i.ocieplenie_dachu,
  i.ocieplenie_scian,
  a.ulica,
  a.miasto,
  w.nazwa_wojewodztwa
FROM SzczegolyKlienta s
JOIN Klienci m ON s.id_klienta = m.id_klienta
JOIN RodzajeOgrzewania ro ON s.id_ogrzewania = ro.id_ogrzewania
JOIN Izolacje i ON s.id_izolacji = i.id_izolacji
JOIN Adresy a ON s.id_adresu = a.id_adresu
JOIN Wojewodztwa w ON a.id_wojewodztwa = w.id_wojewodztwa;





CREATE OR REPLACE VIEW Widok_Aktywnosci_Uzytkownikow AS
SELECT 
  CONCAT(u.imie, ' ', u.nazwisko) AS uzytkownik,
  u.id_kampanii, --
  COUNT(p.id_polaczenia) AS liczba_polaczen,
  SEC_TO_TIME(SUM(p.czas_trwania)) AS laczny_czas_rozmow,
  SUM(p.sukces) AS sukcesy
FROM Uzytkownicy u
LEFT JOIN Polaczenia p 
  ON u.id_uzytkownika = p.id_uzytkownika 
  AND DATE(p.data_polaczenia) = CURDATE()
LEFT JOIN LogiDostepu l 
  ON u.id_uzytkownika = l.id_uzytkownika 
  AND DATE(l.czas_logowania) = CURDATE()
WHERE 
  u.id_roli = 2
GROUP BY 
  u.id_uzytkownika, u.id_kampanii; 

  
  
  
CREATE OR REPLACE VIEW Widok_Analizy_Regionalnej AS
SELECT 
  w.nazwa_wojewodztwa,
  COUNT(DISTINCT a.id_adresu) AS liczba_klientow,
  Round(AVG(s.sukces),2) AS sredni_wskaznik_sukcesu,
  Round(AVG(p.kwota),2) AS srednia_platnosc
FROM Wojewodztwa w
LEFT JOIN Adresy a ON w.id_wojewodztwa = a.id_wojewodztwa
LEFT JOIN SzczegolyKlienta s ON a.id_adresu = s.id_adresu
LEFT JOIN Umowy u ON s.id_szczegolu = u.id_szczegolu
LEFT JOIN Platnosci p ON u.id_umowy = p.id_umowy
GROUP BY w.id_wojewodztwa;

SELECT * from Kampanie k 

SELECT * FROM Widok_Analizy_Regionalnej;

SELECT * FROM Widok_Aktywnosci_Uzytkownikow

SELECT * FROM Widok_Szczegolow_Klienta;

SELECT * FROM Widok_Efektywnosci_Kampanii;
