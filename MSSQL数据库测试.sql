USE [master];
GO


CREATE DATABASE CSV_TESTDB;
GO

USE CSV_TESTDB;
GO

CREATE TABLE dbo.testTable
(
    Id INT NOT NULL,
    FirstName NVARCHAR(250) NOT NULL,
    LastName NVARCHAR(250) NOT NULL,
    Email NVARCHAR(250) NULL
);
GO


INSERT INTO dbo.testTable
(
    Id,
    FirstName,
    LastName,
    Email
)
VALUES
(1, 'Chip', 'Munk', 'Chip.Munk@CSV_TESTDB.com'),
(2, 'Frank', 'Enstein', 'Frank.Enstein@CSV_TESTDB.com'),
(3, 'Penny', 'Wise', 'Penny.Wise@CSV_TESTDB.com');
GO

