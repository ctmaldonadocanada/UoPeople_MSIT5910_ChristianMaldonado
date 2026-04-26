USE DataModelDB
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('Time_Dim') AND type in (N'U'))
BEGIN
CREATE TABLE Time_Dim (
    TimeID INT, -- PK
    [Date] DATE,
	[Year] INT,
	[Quarter] INT,
	[Month] INT,
	[Month Name] VARCHAR(20),
	[YYYY-MM] VARCHAR(7),
	[WeekNumber] INT,
	[Day] INT
);
END
GO