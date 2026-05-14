-- Check count of records

--EXTRACT MODULE
SELECT COUNT(DISTINCT UDF1) AS [Extract count]
FROM [StagingDB].[dbo].[AccessLogs_Table]

-- TRANSFORM MODULE
SELECT COUNT (DISTINCT EmployeeID) AS [Transform count]
from [TransformDB].[dbo].[Attendance_Transform]
WHERE DaysPresent > 0;

-- LOAD MODULE
SELECT COUNT (DISTINCT EmployeeID) AS [Load count]
FROM [DataModelDB].[dbo].[Attendance_Fact]
WHERE DaysPresent > 0;



-- showing that the tables are populated from Staging, Transform, to Data Model (Load) 

--EXTRACT MODULE
SELECT * 
FROM [StagingDB].[dbo].[AccessLogs_Table]

-- TRANSFORM MODULE
SELECT *
from [TransformDB].[dbo].[Attendance_Transform]

-- LOAD MODULE
SELECT *
FROM [DataModelDB].[dbo].[Attendance_Fact]


-- Checking the count between DISTINCT records and no distinct (shows equal value)



select count(*)
from [DataModelDB].[dbo].[Attendance_Fact]

select count (distinct Attendance_Fact_ID)
from [DataModelDB].[dbo].[Attendance_Fact]


select count(*)
from [DataModelDB].[dbo].Employee_Dim

select count (distinct EmployeeID)
from [DataModelDB].[dbo].Employee_Dim