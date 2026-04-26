USE DataModelDB
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Employee_Dim') AND type in (N'U'))
BEGIN
CREATE TABLE Employee_Dim (
    EmployeeID INT, -- PK
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