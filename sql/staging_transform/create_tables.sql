IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '_AccessLogs')
BEGIN
    CREATE DATABASE _AccessLogs;
END
GO


IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '_HR')
BEGIN
    CREATE DATABASE _HR;
END
GO


IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'StagingDB')
BEGIN
    CREATE DATABASE StagingDB;
END
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TransformDB')
BEGIN
    CREATE DATABASE TransformDB;
END
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DataModelDB')
BEGIN
    CREATE DATABASE DataModelDB;
END
GO


USE _AccessLogs
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('AccessLogs') AND type in (N'U'))
BEGIN
CREATE TABLE AccessLogs (
    UDF1 INT,
    [Timestamp] DATETIME,
	EventType VARCHAR(3)
);
END
GO

USE _HR
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Employee') AND type in (N'U'))
BEGIN
CREATE TABLE Employee (
    EmployeeID INT,
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	Gender VARCHAR(10),
	Country VARCHAR(50),
	Region VARCHAR(50),
	Department VARCHAR(50),
	NumberOfYearsInCompany INT,
	Age INT
);
END
GO


USE StagingDB
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('AccessLogs_Table') AND type in (N'U'))
BEGIN
CREATE TABLE AccessLogs_Table (
    UDF1 INT,
    [Timestamp] DATETIME,
	EventType VARCHAR(3)
);
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('EmployeeDetails_Table') AND type in (N'U'))
BEGIN

CREATE TABLE EmployeeDetails_Table (
    EmployeeID INT,
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	Gender VARCHAR(10),
	Country VARCHAR(50),
	Region VARCHAR(50),
	Department VARCHAR(50),
	NumberOfYearsInCompany INT,
	Age INT
);
END
GO

USE TransformDB
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Attendance_Transform') AND type in (N'U'))
BEGIN

CREATE TABLE Attendance_Transform (
    EmployeeID INT,
    [WeekDate] DATETIME,
	[DaysPresent] INT
);
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('EmployeeDetails_Transform') AND type in (N'U'))
BEGIN

CREATE TABLE EmployeeDetails_Transform (
    EmployeeID INT,
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	Gender VARCHAR(10),
	Country VARCHAR(50),
	Region VARCHAR(50),
	Department VARCHAR(50),
	NumberOfYearsInCompany INT,
	Age INT
);
END
GO


-- Insert Dummy Data CSVs to our Source System DBs

USE _HR
GO


TRUNCATE TABLE Employee
-- 2. Execute the Bulk Insert
BULK INSERT Employee
FROM 'C:\Users\63956\source\repos\UoPeople_MSIT5910_ChristianMaldonado\data\Employee_Data.csv' 
WITH (
    DATAFILETYPE  = 'char',          -- Specified for modern SQL Server versions (2017+)
    FIRSTROW = 2,            -- Skips the header row
    FIELDTERMINATOR = ',',    -- Column separator
    ROWTERMINATOR = '0x0a',    -- Line separator (use '0x0a' for Linux-style LF)
    TABLOCK                  -- Locks table during import for better performance
);

USE _AccessLogs
GO

TRUNCATE TABLE AccessLogs

-- 2. Execute the Bulk Insert
BULK INSERT AccessLogs
FROM 'C:\Users\63956\source\repos\UoPeople_MSIT5910_ChristianMaldonado\data\AccessLogs_Data.csv' 
WITH (
    DATAFILETYPE  = 'char',          -- Specified for modern SQL Server versions (2017+)
    FIRSTROW = 2,            -- Skips the header row
    FIELDTERMINATOR = ',',    -- Column separator
    ROWTERMINATOR = '0x0a',    -- Line separator (use '0x0a' for Linux-style LF)
    TABLOCK                  -- Locks table during import for better performance
);




