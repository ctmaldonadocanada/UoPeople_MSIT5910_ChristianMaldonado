USE DataModelDB
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Attendance_Fact') AND type in (N'U'))
BEGIN

CREATE TABLE Attendance_Fact (
    Attendance_Fact_ID INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
	EmployeeID INT, -- FK of Employee_Dim
	TimeID INT, -- FK of Time_Dim
	DaysPresent INT -- measure showing how many days
					-- an employee is present in a week
	
);

END
GO