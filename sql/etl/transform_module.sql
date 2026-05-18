-- TRANSFORM MODULE


-- Parameter
DECLARE @MonthsBack INT = 6; -- considering the latest 6 months data; can be adjusted depending on prune date value adjustment.

-- Attendance TransformDB

-- Step 0: Delete existing data for the same week range (aligned to Monday)
DELETE FROM [TransformDB].[dbo].[Attendance_Transform]
WHERE WeekDate >= DATEADD(
    WEEK,
    DATEDIFF(WEEK, 0, DATEADD(MONTH, -@MonthsBack, GETDATE())),
    0
);

-- Step 1: Generate all Mondays (week starts)
WITH Weeks AS (
    SELECT 
        DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(MONTH, -@MonthsBack, GETDATE())), 0) AS WeekDate
    UNION ALL
    SELECT DATEADD(WEEK, 1, WeekDate)
    FROM Weeks
    WHERE WeekDate < DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)
),

-- Step 2: Actual attendance (distinct days per week)
ActualAttendance AS (
    SELECT 
        UDF1 AS EmployeeID,
        DATEADD(WEEK, DATEDIFF(WEEK, 0, [Timestamp]), 0) AS WeekDate,
        COUNT(DISTINCT CAST([Timestamp] AS DATE)) AS DaysPresent
    FROM [StagingDB].[dbo].[AccessLogs_Table]
    WHERE [Timestamp] >= DATEADD(MONTH, -@MonthsBack, GETDATE())
    GROUP BY 
        UDF1,
        DATEADD(WEEK, DATEDIFF(WEEK, 0, [Timestamp]), 0)
),

-- Step 3: All employees × all weeks (default 0)
ZeroAttendance AS (
    SELECT 
        e.EmployeeID,
        w.WeekDate,
        0 AS DaysPresent
    FROM [StagingDB].[dbo].[EmployeeDetails_Table] e
    CROSS JOIN Weeks w
)

-- Step 4: Combine + aggregate
INSERT INTO [TransformDB].[dbo].[Attendance_Transform]
(
    EmployeeID,
    WeekDate,
    DaysPresent
)
SELECT 
    EmployeeID,
    WeekDate,
    SUM(DaysPresent) AS DaysPresent
FROM (
    SELECT * FROM ActualAttendance
    UNION ALL
    SELECT * FROM ZeroAttendance
) x
GROUP BY 
    EmployeeID,
    WeekDate
OPTION (MAXRECURSION 1000); -- tells MS SQL Server to allow up to 1000 recursive iterations before stopping


-- Step 5: making sure we don't have 0 data in the [TransformDB].[dbo].[Attendance_Transform] for those weeks that we don't really have value from the source SYSTEM
DECLARE @MinTimestamp DATETIME;

SELECT @MinTimestamp = MIN([Timestamp])
FROM [_AccessLogs].[dbo].[AccessLogs];

IF @MinTimestamp IS NOT NULL
BEGIN
    DELETE FROM [TransformDB].[dbo].[Attendance_Transform]
    WHERE WeekDate < DATEADD(
        WEEK,
        DATEDIFF(WEEK, 0, @MinTimestamp),
        0
    );
END;

DELETE FROM [TransformDB].[dbo].[Attendance_Transform]
WHERE WeekDate IN (
    SELECT WeekDate
    FROM [TransformDB].[dbo].[Attendance_Transform]
    GROUP BY WeekDate
    HAVING SUM(DaysPresent) = 0
); -- delete records where the sum of the presentdate is 0 for those whole weekdate (added 2026/05/17)

-- Employee TransformDB

-- 1. Truncate target table
TRUNCATE TABLE [TransformDB].[dbo].[EmployeeDetails_Transform];

-- 2. Insert data from staging (full load as this is a master table not transaction)
INSERT INTO [TransformDB].[dbo].[EmployeeDetails_Transform]
(
    EmployeeID,
    FirstName,
    LastName,
    Gender,
    Country,
    Region,
    Department,
    NumberOfYearsInCompany,
    Age
)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Gender,
    Country,
    Region,
    Department,
    NumberOfYearsInCompany,
    Age
FROM [StagingDB].[dbo].[EmployeeDetails_Table];