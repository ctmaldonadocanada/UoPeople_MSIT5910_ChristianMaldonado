-- EXTRACT MODULE


-- Declare variable for number of months
DECLARE @MonthsBack INT = 3;

-- Check if staging table has data
IF EXISTS (SELECT 1 FROM [StagingDB].[dbo].[AccessLogs_Table])
BEGIN
    -- Incremental load

    DELETE FROM [StagingDB].[dbo].[AccessLogs_Table]
    WHERE [Timestamp] >= DATEADD(MONTH, -@MonthsBack, GETDATE());

    INSERT INTO [StagingDB].[dbo].[AccessLogs_Table]
    SELECT *
    FROM [_AccessLogs].[dbo].[AccessLogs]
    WHERE [Timestamp] >= DATEADD(MONTH, -@MonthsBack, GETDATE());
END
ELSE
BEGIN
    -- Full load

    INSERT INTO [StagingDB].[dbo].[AccessLogs_Table]
    SELECT *
    FROM [_AccessLogs].[dbo].[AccessLogs];
END;

-- Employee table (still full load as it's a master file not transaction)

TRUNCATE TABLE [StagingDB].[dbo].[EmployeeDetails_Table]
INSERT INTO [StagingDB].[dbo].[EmployeeDetails_Table]
(
    [EmployeeID],
    [FirstName],
    [LastName],
    [Gender],
    [Country],
    [Region],
    [Department],
    [NumberOfYearsInCompany],
    [Age]
)
SELECT 
    [EmployeeID],
    [FirstName],
    [LastName],
    [Gender],
    [Country],
    [Region],
    [Department],
    [NumberOfYearsInCompany],
    [Age]
FROM [_HR].[dbo].[Employee];


-- test script
--select count(*) from [StagingDB].[dbo].[AccessLogs_Table] -- staging
--select count(*) from [_AccessLogs].[dbo].[AccessLogs] -- source