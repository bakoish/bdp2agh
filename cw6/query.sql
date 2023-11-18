BEGIN TRY
    DROP TABLE AdventureWorksDW2019.dbo.stg_dimemp;
END TRY
BEGIN CATCH
    PRINT 'Tabela AdventureWorksDW2019.dbo.stg_dimemp nie istnieje.';
END CATCH

SELECT EmployeeKey, FirstName, LastName, Title 
INTO AdventureWorksDW2019.dbo.stg_dimemp
FROM dbo.DimEmployee
WHERE EmployeeKey BETWEEN 270 AND 275;

BEGIN TRY
    DROP TABLE AdventureWorksDW2019.dbo.scd_dimemp;
END TRY
BEGIN CATCH
    PRINT 'Tabela AdventureWorksDW2019.dbo.scd_dimemp nie istnieje.';
END CATCH

CREATE TABLE AdventureWorksDW2019.dbo.scd_dimemp (
	EmployeeKey int ,
	FirstName nvarchar(50) not null,
	LastName nvarchar(50) not null,
	Title nvarchar(50),
	StartDate datetime,
	EndDate datetime
);

update STG_DimEmp
set LastName = 'Nowak'
where EmployeeKey = 270;

update STG_DimEmp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;

update STG_DimEmp 
set FIRSTNAME = 'Ryszard' 
where EmployeeKey = 275

-- zad 6
-- SCD Typ 1 nadpisanie
-- SCD Typ 2 nowy record
-- SCD Typ 0 brak aktualizacji

-- zad 7
-- Mialo wplyw ustawienie Fixed attribute dla atrybutu FirstName
-- co blokuje zmiane
