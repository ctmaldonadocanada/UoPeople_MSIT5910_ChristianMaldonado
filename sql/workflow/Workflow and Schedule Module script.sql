USE [msdb]
GO

/****** Object:  Job [RTO Workflow]    Script Date: 5/18/2026 3:33:54 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/18/2026 3:33:54 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'RTO Workflow', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This is the workflow and schedule module of the:

Design and Development of an Integrated Data Pipeline for Monitoring Return-to-Office Compliance Using Access Logs and HR Data 
A Capstone Project Report of MSIT 5910

Submitted by:

Christian T. Maldonado (S559425)

For the partial fulfilment of the requirements for the degree of
 Master of Science in Information Technology

Supervised by:
Dr. Shabia Shabir', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'LAPTOP-VFHMNTHB\cmaldonado', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Extract Module]    Script Date: 5/18/2026 3:33:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Extract Module', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- EXTRACT MODULE

-- Declare variable for number of months
DECLARE @MonthsBack INT = 6;

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

-- Employee table (still full load as it''s a master file not transaction)

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
FROM [_HR].[dbo].[Employee];', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Transform Module]    Script Date: 5/18/2026 3:33:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Transform Module', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- TRANSFORM MODULE


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


-- Step 5: making sure we don''t have 0 data in the [TransformDB].[dbo].[Attendance_Transform] for those weeks that we don''t really have value from the source SYSTEM
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
FROM [StagingDB].[dbo].[EmployeeDetails_Table];', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Module]    Script Date: 5/18/2026 3:33:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Module', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- LOAD MODULE

-- =========================================
-- 1. TIME DIMENSION (INSERT ONLY IF EMPTY)
-- =========================================

IF NOT EXISTS (
    SELECT TOP 1 1 FROM [DataModelDB].[dbo].[Time_Dim]
)
BEGIN
    WITH Dates AS (
        SELECT CAST(''2025-01-01'' AS DATE) AS [Date]
        UNION ALL
        SELECT DATEADD(DAY, 1, [Date])
        FROM Dates
        WHERE [Date] < ''2027-12-31''
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
        CONVERT(INT, FORMAT([Date], ''yyyyMMdd'')) AS TimeID,
        [Date],
        YEAR([Date]) AS [Year],
        DATEPART(QUARTER, [Date]) AS [Quarter],
        MONTH([Date]) AS [Month],
        DATENAME(MONTH, [Date]) AS [Month Name],
        FORMAT([Date], ''yyyy-MM'') AS [YYYY-MM],
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
    ON T.[Date] = A.WeekDate;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run 1:00 AM EST Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20260518, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'54a8f7f2-094e-4b4d-add5-f5830f84c091'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


