-- LOAD MODULE

-- =========================================
-- 1. TIME DIMENSION (INSERT ONLY IF EMPTY)
-- =========================================

IF NOT EXISTS (
    SELECT TOP 1 1 FROM [DataModelDB].[dbo].[Time_Dim]
)
BEGIN
    WITH Dates AS (
        SELECT CAST('2025-01-01' AS DATE) AS [Date]
        UNION ALL
        SELECT DATEADD(DAY, 1, [Date])
        FROM Dates
        WHERE [Date] < '2027-12-31'
    )
    INSERT INTO [DataModelDB].[dbo].[Time_Dim]
    (
        TimeID,
        [Date],
        [Year],
        [Quarter],
        [Month],
        [Month Name],
        [YYYY-MM],
        [WeekNumber],
        [Day]
    )
    SELECT 
        CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS TimeID,
        [Date],
        YEAR([Date]) AS [Year],
        DATEPART(QUARTER, [Date]) AS [Quarter],
        MONTH([Date]) AS [Month],
        DATENAME(MONTH, [Date]) AS [Month Name],
        FORMAT([Date], 'yyyy-MM') AS [YYYY-MM],
        DATEPART(WEEK, [Date]) AS WeekNumber,
        DAY([Date]) AS [Day]
    FROM Dates
    OPTION (MAXRECURSION 2000);
END;


-- =========================================
-- 2. EMPLOYEE DIMENSION (FULL LOAD)
-- =========================================

TRUNCATE TABLE [DataModelDB].[dbo].[Employee_Dim];

INSERT INTO [DataModelDB].[dbo].[Employee_Dim]
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
FROM [TransformDB].[dbo].[EmployeeDetails_Transform];


-- =========================================
-- 3. ATTENDANCE FACT (INCREMENTAL BY WEEK)
-- =========================================

-- Step 1: Delete only affected weeks
DELETE F
FROM [DataModelDB].[dbo].[Attendance_Fact] F
WHERE EXISTS (
    SELECT 1
    FROM [TransformDB].[dbo].[Attendance_Transform] A
    WHERE A.WeekDate = (
        SELECT T.[Date]
        FROM [DataModelDB].[dbo].[Time_Dim] T
        WHERE T.TimeID = F.TimeID
    )
);

-- Step 2: Insert refreshed data
INSERT INTO [DataModelDB].[dbo].[Attendance_Fact]
(
    EmployeeID,
    TimeID,
    DaysPresent
)
SELECT 
    A.EmployeeID,
    T.TimeID,
    A.DaysPresent
FROM [TransformDB].[dbo].[Attendance_Transform] A
JOIN [DataModelDB].[dbo].[Time_Dim] T
    ON T.[Date] = A.WeekDate;