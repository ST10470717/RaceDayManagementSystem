
-- =============================================
-- EVENT MANAGEMENT SYSTEM
-- Database Schema
-- SQL Server / T-SQL
-- =============================================

-- 1. ROLES TABLE
CREATE TABLE Roles
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(30) NOT NULL UNIQUE
);

-- 2. USERS TABLE
CREATE TABLE Users
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    RoleID INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Users_Roles
        FOREIGN KEY (RoleID)
        REFERENCES Roles(RoleID)
);

-- 3. CATEGORIES TABLE
CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(250) NULL
);

-- 4. EVENTS TABLE
CREATE TABLE Events
(
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    Location NVARCHAR(150) NOT NULL,
    EventDate DATETIME2 NOT NULL,
    DistanceKM DECIMAL(6,2) NOT NULL
        DEFAULT 0,
    EventType NVARCHAR(20) NOT NULL,
    OrganiserID INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Events_Users
        FOREIGN KEY (OrganiserID)
        REFERENCES Users(UserID),

    CONSTRAINT CK_Events_Distance
        CHECK (DistanceKM >= 0),

    CONSTRAINT CK_Events_Type
        CHECK (EventType IN ('Run', 'Walk', 'Cycle'))
);

-- 5. EVENT CATEGORIES TABLE
CREATE TABLE EventCategories
(
    EventID INT NOT NULL,
    CategoryID INT NOT NULL,

    CONSTRAINT PK_EventCategories
        PRIMARY KEY (EventID, CategoryID),

    CONSTRAINT FK_EventCategories_Events
        FOREIGN KEY (EventID)
        REFERENCES Events(EventID),

    CONSTRAINT FK_EventCategories_Categories
        FOREIGN KEY (CategoryID)
        REFERENCES Categories(CategoryID)
);

-- 6. ENROLMENTS TABLE
CREATE TABLE Enrolments
(
    EnrolmentID INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID INT NOT NULL,
    EventID INT NOT NULL,
    EnrolmentDate DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),
    FinishTime TIME NULL,
    FinishingPosition INT NULL,
    ResultStatus NVARCHAR(20) NOT NULL
        DEFAULT 'Registered',

    CONSTRAINT FK_Enrolments_Users
        FOREIGN KEY (ParticipantID)
        REFERENCES Users(UserID),

    CONSTRAINT FK_Enrolments_Events
        FOREIGN KEY (EventID)
        REFERENCES Events(EventID),

    CONSTRAINT UQ_Enrolments_Participant_Event
        UNIQUE (ParticipantID, EventID),

    CONSTRAINT CK_Enrolments_Position
        CHECK (FinishingPosition IS NULL
               OR FinishingPosition > 0),

    CONSTRAINT CK_Enrolments_Status
        CHECK (ResultStatus IN
        ('Registered', 'Completed', 'Withdrawn'))
);

-- =============================================
-- SEED DATA
-- =============================================

-- Roles
INSERT INTO Roles (RoleName)
VALUES ('Organiser'), ('Participant');

-- Categories
INSERT INTO Categories (CategoryName, Description)
VALUES
('Beginner', 'Suitable for beginners'),
('Intermediate', 'For participants with some experience'),
('Advanced', 'For experienced participants');

-- Sample users
-- PasswordHash values below are placeholders for
-- database planning only, NOT real password hashes.
INSERT INTO Users
    (FullName, Email, PasswordHash, RoleID)
VALUES
(
    'Sample Organiser',
    'organiser@example.com',
    'PLACEHOLDER_HASH_1',
    (SELECT RoleID FROM Roles WHERE RoleName = 'Organiser')
),
(
    'Sample Participant',
    'participant@example.com',
    'PLACEHOLDER_HASH_2',
    (SELECT RoleID FROM Roles WHERE RoleName = 'Participant')
);

-- Sample event
INSERT INTO Events
    (EventName, Description, Location, EventDate,
     DistanceKM, EventType, OrganiserID)
VALUES
(
    'Community Fun Run',
    'A community running event for all skill levels.',
    'Pretoria',
    '2027-03-20T08:00:00',
    5.00,
    'Run',
    (SELECT UserID FROM Users
     WHERE Email = 'organiser@example.com')
);

-- Link the event to a category
INSERT INTO EventCategories (EventID, CategoryID)
VALUES
(
    (SELECT EventID FROM Events
     WHERE EventName = 'Community Fun Run'),
    (SELECT CategoryID FROM Categories
     WHERE CategoryName = 'Beginner')
);

-- Enrol the sample participant
INSERT INTO Enrolments (ParticipantID, EventID)
VALUES
(
    (SELECT UserID FROM Users
     WHERE Email = 'participant@example.com'),
    (SELECT EventID FROM Events
     WHERE EventName = 'Community Fun Run')
);

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- View users and their roles
SELECT
    U.UserID,
    U.FullName,
    U.Email,
    R.RoleName
FROM Users U
INNER JOIN Roles R ON U.RoleID = R.RoleID;

-- View events, organisers and categories
SELECT
    E.EventID,
    E.EventName,
    E.Location,
    E.EventDate,
    E.EventType,
    U.FullName AS Organiser,
    C.CategoryName
FROM Events E
INNER JOIN Users U ON E.OrganiserID = U.UserID
LEFT JOIN EventCategories EC ON E.EventID = EC.EventID
LEFT JOIN Categories C ON EC.CategoryID = C.CategoryID;

-- View participant enrolments and results
SELECT
    EN.EnrolmentID,
    U.FullName AS Participant,
    E.EventName,
    EN.EnrolmentDate,
    EN.FinishTime,
    EN.FinishingPosition,
    EN.ResultStatus
FROM Enrolments EN
INNER JOIN Users U ON EN.ParticipantID = U.UserID
INNER JOIN Events E ON EN.EventID = E.EventID;

