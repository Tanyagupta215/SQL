use AdventureWorks2008R2
Go

--Exercise1
--1.
SELECT count(*) from Sales.SalesPerson;

--2.
SELECT FirstName , LastName from Person.Person
WHERE FirstName LIKE 'B%';

--3.
SELECT Person.Person.FirstName, Person.Person.LastName , HumanResources.Employee.JobTitle
from Person.Person
inner join
HumanResources.Employee
ON Person.Person.BusinessEntityID = HumanResources.Employee.BusinessEntityID
WHERE HumanResources.Employee.JobTitle IN ('Design Engineer','Tool Designer', 'Marketing Assistant')
Order by Person.FirstName asc;

--4.
SELECT Name, Color from Production.Product 
WHERE Weight=(SELECT MAX(Weight) from Production.Product);

--5.
SELECT Description, ISNULL(MaxQty,0.00) from Sales.SpecialOffer;

--6.
SELECT AVG(AverageRate) as AverageExachangeForTheDay from Sales.CurrencyRate
WHERE datepart(Year,CurrencyRateDate) = 2005 and ToCurrencyCode ='GBP'

--7.
SELECT ROW_NUMBER() OVER(ORDER BY FIRSTNAME ASC) AS RowId, FirstName, LastName  from Person.Person
WHERE FirstName LIKE '%ss%';

--8
SELECT BusinessEntityID,
CommissionBand = CASE   
      WHEN CommissionPct = 0.00 THEN 'Band0'
	  WHEN CommissionPct >0.00 AND CommissionPct <1 THEN 'Band1'
	  WHEN CommissionPct >1 AND CommissionPct <1.5 THEN 'Band2'
      else 'Band3'   
   END
from Sales.SalesPerson;

--9.
Declare @EmpID int
SELECT @EmpId = BusinessEntityID from Person.Person 
WHERE FirstName ='Ruth' AND PersonType ='EM'

EXEC dbo.uspGetEmployeeManagers @EmpID 

--10.
--SELECT * from Production.ProductInventory
--where ProductID = 528

--SELECT ProductID from Production.Product
--where dbo.ufnGetStock(ProductID) = (SELECT MAX(dbo.ufnGetStock(ProductID)) from Production.Product);

SELECT top 1 (ProductID) from (SELECT SUM(Quantity) as Stock ,ProductID from Production.ProductInventory
									Group by ProductID) productStock 
									Order by Stock Desc;

SELECT top 1(ProductID) from Production.ProductInventory
Group by ProductID 
Order by SUM(Quantity) DESC


--SELECT ProductID,SUM(Quantity) from Production.ProductInventory
--Group by ProductID;





alter FUNCTION [dbo].[ufnGetStock](@ProductID [int])
RETURNS [int] 
AS 
-- Returns the stock level for the product. This function is used internally only
BEGIN
    DECLARE @ret int;
    
    SELECT @ret = MAX(p.[Quantity]) 
    FROM [Production].[ProductInventory] p 
    WHERE p.[ProductID] = @ProductID 
	Group by p.ProductID
        --AND p.[LocationID] = '6'; -- Only look at inventory in the misc storage
    
    IF (@ret IS NULL) 
        SET @ret = 0
    
    RETURN @ret
END;


--EXERCISE 2
--SELECT * from Person.Person
--SELECT * from Sales.Customer

--JOIN
SELECT FirstName, LastName from Person.Person
Inner join Sales.Customer on Person.BusinessEntityID = Customer.CustomerID
left join Sales.SalesOrderHeader on Customer.CustomerID = SalesOrderHeader.CustomerID
WHERE SalesOrderID IS NULL

--SUBQUERY
SELECT FirstName, LastName from Person.Person
WHERE BusinessEntityID IN (
							SELECT CustomerID from Sales.Customer
							WHERE CustomerID NOT IN (
														SELECT CustomerID from Sales.SalesOrderHeader))

--CTE
WITH CustomerOrderNotPlaced
as
(
	SELECT FirstName, LastName from Person.Person
	WHERE BusinessEntityID IN (
								SELECT CustomerID from Sales.Customer
								WHERE CustomerID NOT IN (
															SELECT CustomerID from Sales.SalesOrderHeader))
)
SELECT * from CustomerOrderNotPlaced

--EXISTS
SELECT FirstName, LastName from Person.Person
WHERE EXISTS 
			(SELECT CustomerID from Sales.Customer
			WHERE Customer.CustomerID = Person.BusinessEntityID
			And not EXISTS
						(SELECT SalesOrderHeader.CustomerID from Sales.SalesOrderHeader
						WHERE Customer.CustomerID = SalesOrderHeader.CustomerID))
	
	

--EXERCISE 3
--SELECT * from Sales.SalesOrderHeader

SELECT top 5(AccountNumber),OrderDate, TotalDue from Sales.SalesOrderHeader
WHERE TotalDue >70000
Order by OrderDate Desc



--EXERCISE 4
--FUNCTION

CREATE FUNCTION fn_GetExchangeRateByDate(@SalesID int, @CurrencyCode varchar(3), @byDate date)
returns @mytable table(Quantity int, ProductID int, UnitPrice money, ConvertedPrice money)
as
BEGIN
insert into @mytable
SELECT OrderQty,ProductID,UnitPrice, UnitPrice*EndOfDayRate as ConvertedPrice from Sales.SalesOrderDetail
inner join Sales.CurrencyRate on SalesOrderDetail.SalesOrderDetailID = CurrencyRate.CurrencyRateID
WHERE SalesOrderID = @salesID and ToCurrencyCode = @CurrencyCode and CurrencyRateDate = @byDate
return 
END

SELECT * from [dbo].[fn_GetExchangeRateByDate] (43659, 'CNY', '2005-07-01');


--EXERCISE 5
--PROCEDURE

Create Procedure spGetNameInfo
@FirstName varchar(10)
as
begin
SELECT FirstName, MiddleName, LastName  from Person.Person WHERE FirstName = @FirstName;
end
	
spGetNameInfo 'ken'

alter Procedure spGetNameInfo
@FirstName varchar(10) ='Michael'
as
begin
SELECT FirstName, MiddleName, LastName  from Person.Person WHERE FirstName = @FirstName;
end
		
spGetNameInfo 

--EXERCISE 6
--TRIGGER


SELECT * from Production.Product
WHERE ProductID = 680

CREATE TRIGGER tr_CheckListPrice
on Production.Product
After Update
as
if EXISTS
(
SELECT * from inserted
inner join deleted 
on inserted.ProductID = deleted.ProductID
WHERE inserted.ListPrice > (deleted.ListPrice *1.15)
)

BEGIN
RAISERROR (15600,-1,-1, 'ListPrice cannot be more than 15 Percent');
ROLLBACK TRAN
END



update Production.Product SET ListPrice = 1826.5
WHERE ProductID = 680


ALTER TRIGGER Production.tr_CheckListPrice
on Production.Product
For Update
as
if UPDATE(ListPrice)
BEGIN

if EXISTS
(
SELECT * from inserted
inner join deleted 
on inserted.ProductID = deleted.ProductID
WHERE inserted.ListPrice > (deleted.ListPrice *1.15)
)

BEGIN
RAISERROR (15600,-1,-1, 'ListPrice cannot be more than 15 Percent');
ROLLBACK TRAN
END
END

update Production.Product SET ListPrice = 1846.25
WHERE ProductID = 680


