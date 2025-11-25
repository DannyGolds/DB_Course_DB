CREATE EXCEPTION Invalid_Dimensions 'Ширина и длина должны быть положительными!';

CREATE TABLE Buildings (
    BuildingID INTEGER NOT NULL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Image BLOB SUB_TYPE BINARY
);

CREATE TABLE Departments (
    DepartmentID INTEGER NOT NULL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    ParentID INTEGER,
    FOREIGN KEY (ParentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE RoomResponsible (
    RoomResponsibleID INTEGER NOT NULL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    JobPosition VARCHAR(100),
    DepartmentID INTEGER,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE Users (
    UserID INTEGER NOT NULL PRIMARY KEY,
    RoomResponsibleID INTEGER NOT NULL,
    Login VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    AccessLevel VARCHAR(20) NOT NULL,
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (RoomResponsibleID) REFERENCES RoomResponsible(RoomResponsibleID)
);

CREATE TABLE Rooms (
    RoomID INTEGER NOT NULL PRIMARY KEY,
    BuildingID INTEGER NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Number VARCHAR(20) NOT NULL,
    Width DECIMAL(5,2) NOT NULL,
    Length DECIMAL(5,2) NOT NULL,
    Purpose VARCHAR(200),
    RoomResponsibleID INTEGER NOT NULL,
    DepartmentID INTEGER NOT NULL,
    Image BLOB SUB_TYPE BINARY,
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    FOREIGN KEY (RoomResponsibleID) REFERENCES RoomResponsible(RoomResponsibleID)
);

CREATE TABLE Equipment (
    EquipmentID INTEGER NOT NULL PRIMARY KEY,
    RoomID INTEGER NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(200),
    Image BLOB SUB_TYPE BINARY,
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID)
);

CREATE GENERATOR Gen_BuildingID;
CREATE GENERATOR Gen_DepartmentID;
CREATE GENERATOR Gen_RoomID;
CREATE GENERATOR Gen_EquipmentID;
CREATE GENERATOR Gen_RoomResponsibleID;
CREATE GENERATOR Gen_UserID;

SET TERM ^ ;

CREATE TRIGGER Buildings_BI FOR Buildings ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.BuildingID IS NULL) THEN NEW.BuildingID = GEN_ID(Gen_BuildingID, 1);
END^

CREATE TRIGGER Departments_BI FOR Departments ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.DepartmentID IS NULL) THEN NEW.DepartmentID = GEN_ID(Gen_DepartmentID, 1);
END^

CREATE TRIGGER RoomResponsible_BI FOR RoomResponsible ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.RoomResponsibleID IS NULL) THEN NEW.RoomResponsibleID = GEN_ID(Gen_RoomResponsibleID, 1);
END^

CREATE TRIGGER Rooms_BI FOR Rooms ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.UserID IS NULL) THEN NEW.UserID = GEN_ID(Gen_UserID, 1);
END^

CREATE TRIGGER Rooms_BI FOR Rooms ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.RoomID IS NULL) THEN NEW.RoomID = GEN_ID(Gen_RoomID, 1);
END^

CREATE TRIGGER Equipment_BI FOR Equipment ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.EquipmentID IS NULL) THEN NEW.EquipmentID = GEN_ID(Gen_EquipmentID, 1);
END^

CREATE TRIGGER Persons_BI FOR Persons ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
    IF (NEW.PersonID IS NULL) THEN NEW.PersonID = GEN_ID(Gen_PersonID, 1);
END^

CREATE TRIGGER Rooms_Check FOR Rooms ACTIVE BEFORE INSERT OR UPDATE POSITION 0 AS
BEGIN
    IF (NEW.Width <= 0 OR NEW.Length <= 0) THEN
        EXCEPTION Invalid_Dimensions;
END^

SET TERM ; ^

CREATE PROCEDURE GetDepartmentInfo (DepID INTEGER)
RETURNS (
    RoomCount INTEGER,
    RoomNames VARCHAR(500),
    EquipmentList VARCHAR(1000)
)
AS
DECLARE VARIABLE RoomID INTEGER;
DECLARE VARIABLE RoomName VARCHAR(100);
DECLARE VARIABLE EquipName VARCHAR(100);
BEGIN
    RoomCount = 0;
    RoomNames = '';
    EquipmentList = '';

    FOR SELECT R.RoomID, R.Type || ' ' || R.Number AS RoomName
        FROM Rooms R
        WHERE R.DepartmentID = :DepID
        INTO :RoomID, :RoomName
    DO
    BEGIN
        RoomCount = RoomCount + 1;
        RoomNames = RoomNames || RoomName || '; ';

        FOR SELECT E.Name
            FROM Equipment E
            WHERE E.RoomID = :RoomID
            INTO :EquipName
        DO
            EquipmentList = EquipmentList || EquipName || ' (в ' || RoomName || '); ';
    END

    SUSPEND;
END;

CREATE PROCEDURE GetBuildingInfo (BuildID INTEGER)
RETURNS (
    RoomCount INTEGER,
    RoomNames VARCHAR(500),
    EquipmentList VARCHAR(1000)
)
AS
DECLARE VARIABLE RoomID INTEGER;
DECLARE VARIABLE RoomName VARCHAR(100);
DECLARE VARIABLE EquipName VARCHAR(100);
BEGIN
    RoomCount = 0;
    RoomNames = '';
    EquipmentList = '';

    FOR SELECT R.RoomID, R.Type || ' ' || R.Number AS RoomName
        FROM Rooms R
        WHERE R.BuildingID = :BuildID
        INTO :RoomID, :RoomName
    DO
    BEGIN
        RoomCount = RoomCount + 1;
        RoomNames = RoomNames || RoomName || '; ';

        FOR SELECT E.Name
            FROM Equipment E
            WHERE E.RoomID = :RoomID
            INTO :EquipName
        DO
            EquipmentList = EquipmentList || EquipName || ' (в ' || RoomName || '); ';
    END

    SUSPEND;
END;

-- Вставки данных (Image = NULL для теста)
INSERT INTO Buildings (Name, Type, Image) VALUES ('Корпус A', 'Учебный', NULL);
INSERT INTO Buildings (Name, Type, Image) VALUES ('Корпус B', 'Административный', NULL);
INSERT INTO Buildings (Name, Type, Image) VALUES ('Корпус C', 'Лабораторный', NULL);
INSERT INTO Buildings (Name, Type, Image) VALUES ('Корпус D', 'Спортивный', NULL);
INSERT INTO Buildings (Name, Type, Image) VALUES ('Корпус E', 'Библиотечный', NULL);

INSERT INTO Departments (Name, ParentID) VALUES ('Ректорат', NULL);
INSERT INTO Departments (Name, ParentID) VALUES ('Факультет ИТ', 1);
INSERT INTO Departments (Name, ParentID) VALUES ('Кафедра Программирования', 2);
INSERT INTO Departments (Name, ParentID) VALUES ('Факультет Экономики', 1);
INSERT INTO Departments (Name, ParentID) VALUES ('Кафедра Финансов', 4);
INSERT INTO Departments (Name, ParentID) VALUES ('Библиотека', NULL);
INSERT INTO Departments (Name, ParentID) VALUES ('Спортивный отдел', NULL);
INSERT INTO Departments (Name, ParentID) VALUES ('Лаборатории', 2);
INSERT INTO Departments (Name, ParentID) VALUES ('Администрация', 1);
INSERT INTO Departments (Name, ParentID) VALUES ('Студенческий совет', 1);

INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Иванов И.И.', 'Декан', 2);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Петров П.П.', 'Профессор', 3);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Сидоров С.С.', 'Доцент', 3);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Кузнецов К.К.', 'Ассистент', 2);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Смирнов С.М.', 'Библиотекарь', 6);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Волков В.В.', 'Администратор', 9);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Морозов М.М.', 'Тренер', 7);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Новиков Н.Н.', 'Инженер', 8);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Егоров Е.Е.', 'Куратор', 2);
INSERT INTO RoomResponsible (Name, JobPosition, DepartmentID) VALUES ('Козлов К.К.', 'Куратор', 4);

INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (1, 'Аудитория', '101', 10.5, 15.2, 'Лекции', 1, 2, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (1, 'Аудитория', '102', 8.0, 12.0, 'Практика', 2, 3, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (1, 'Лаборатория', '201', 12.0, 18.0, 'Вычисления', 3, 8, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (2, 'Кабинет', '301', 6.0, 8.0, 'Администрация', 6, 9, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (3, 'Лаборатория', '401', 15.0, 20.0, 'Исследования', 4, 3, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (4, 'Спортзал', '501', 25.0, 30.0, 'Тренировки', 7, 7, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (5, 'Читальный зал', '601', 10.0, 14.0, 'Учеба', 5, 6, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (2, 'Конференц-зал', '302', 12.0, 16.0, 'Встречи', 1, 1, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (3, 'Аудитория', '402', 9.0, 13.5, 'Семинары', 2, 4, NULL);
INSERT INTO Rooms (BuildingID, Type, Number, Width, Length, Purpose, RoomResponsibleID, DepartmentID, Image) VALUES (4, 'Раздевалка', '502', 5.0, 7.0, 'Хранение', 7, 7, NULL);

INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (1, 'Проектор', 'Epson 4K', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (1, 'Доска', 'Интерактивная', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (2, 'Компьютер', 'Dell OptiPlex', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (2, 'Монитор', 'LG 27 inch', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (3, 'Сервер', 'Fujitsu', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (3, 'Коммутатор', 'Cisco', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (4, 'Принтер', 'HP LaserJet', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (5, 'Микроскоп', 'Leica', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (5, 'Центрифуга', 'Eppendorf', NULL);
INSERT INTO Equipment (RoomID, Name, Description, Image) VALUES (6, 'Беговая дорожка', 'Precor', NULL);

INSERT INTO Users (RoomResponsibleID, Login, PasswordHash, AccessLevel) VALUES (1, 'admin', 'hash_password_123', 'ADMIN');
INSERT INTO Users (RoomResponsibleID, Login, PasswordHash, AccessLevel) VALUES (2, 'professor_petrov', 'hash_password_456', 'USER');
INSERT INTO Users (RoomResponsibleID, Login, PasswordHash, AccessLevel) VALUES (6, 'admin_volkov', 'hash_password_789', 'ADMIN');
INSERT INTO Users (RoomResponsibleID, Login, PasswordHash, AccessLevel) VALUES (9, 'curator_egorov', 'hash_password_012', 'USER');