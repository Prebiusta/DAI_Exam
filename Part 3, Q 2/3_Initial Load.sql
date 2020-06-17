-- *******************************************************************
-- ************ INSERTING AND FIXING DATA IN STAGE TABLES ************
-- *******************************************************************

-- _______________________ DATE _______________________

--This statement inserts attribute values unto staging dimension table stage_dim_date
DECLARE @StartDate DATETIME = '2011-05-31';
DECLARE @EndDate DATETIME = '2014-06-30';

WHILE @StartDate <= @EndDate
    BEGIN
        INSERT INTO AdventureWorks_DW.star_schema.d_date (date,
                                                          day_name,
                                                          month_name)
        SELECT @StartDate,
               DATENAME(weekday, @StartDate),
               DATENAME(month, @StartDate);

        SET @StartDate = DATEADD(dd, 1, @StartDate);
    END;


-- _______________________ Price Range _______________________

-- Pre-populate current_price table with this data. Data ranges will be 200
DECLARE @StartPrice decimal(10, 2) = 0.00;
DECLARE @EndPrice decimal(10, 2) = 199.99;
DECLARE @Increment decimal(10, 2) = 200.00;

DECLARE @MaxPrice decimal(10, 2) = (SELECT MAX(ListPrice)
                                    FROM AdventureWorks2017.Production.Product) + 200;

WHILE @EndPrice <= @MaxPrice
    BEGIN
        INSERT INTO AdventureWorks_DW.star_schema.d_price_range (start_price, end_price)
        VALUES (@StartPrice,
                @EndPrice);
        SET @StartPrice = @StartPrice + @Increment;
        SET @EndPrice = @EndPrice + @Increment;
    END


-- _______________________ CUSTOMER _______________________

--This statement inserts attribute values into staging dimension table stage_dim_customer
INSERT INTO StagingDatabase.staging.stage_dim_customer(customer_id, title, first_name, middle_name, last_name)
SELECT CustomerID, Title, FirstName, MiddleName, LastName
FROM AdventureWorks2017.Sales.Customer
         JOIN AdventureWorks2017.Person.Person ON Customer.PersonID = Person.BusinessEntityID;

--This statement removes null values in the title attribute in stage_dim_customer table by replacing with 'N/A'
UPDATE StagingDatabase.staging.stage_dim_customer
SET title='N/A'
WHERE title IS NULL;

--This statement removes null values in the middle_name attribute in stage_dim_customer table by replacing with 'N/A'
UPDATE StagingDatabase.staging.stage_dim_customer
SET middle_name='N/A'
WHERE middle_name IS NULL;

-- Create new date for valid_from attribute. It will be the date when it was added to data warehouse
UPDATE StagingDatabase.staging.stage_dim_customer
SET valid_from=GETDATE()
WHERE valid_from IS NULL;

-- This statement replaces all NULL values with date 31.12.9999
UPDATE StagingDatabase.staging.stage_dim_customer
SET valid_to='9999-12-31'
WHERE valid_to IS NULL;


-- _______________________ PRODUCT _______________________

--This statement inserts attribute values into staging dimension table stage_dim_product
INSERT INTO StagingDatabase.staging.stage_dim_product(product_id, name, valid_from, valid_to, price)
SELECT ProductID, Name, SellStartDate, SellEndDate, ListPrice
from AdventureWorks2017.Production.Product;

--This statement removes null values in the name attribute in stage_dim_product table by replacing with 'N/A'
UPDATE StagingDatabase.staging.stage_dim_product
SET name='N/A'
WHERE name IS NULL;

-- This statement replaces all NULL values with date 31.12.9999
UPDATE StagingDatabase.staging.stage_dim_product
SET valid_to='9999-12-31'
WHERE valid_to IS NULL;

-- Update reference to price range
UPDATE StagingDatabase.staging.stage_dim_product
SET price_range_id = (SELECT dimension_price_range_id
                      FROM AdventureWorks_DW.star_schema.d_price_range
                      WHERE price BETWEEN start_price AND end_price)
WHERE price_range_id IS NULL;

-- ***********************************************************************
-- ************ INSERTING FIXED DATA INTO DW DIMENSION TABLES ************
-- ***********************************************************************

--This statement inserts attribute vales into dimension d_product table
INSERT INTO AdventureWorks_DW.star_schema.d_product (product_id, price_range_id, name, valid_from, valid_to)
SELECT product_id, price_range_id, name, valid_from, valid_to
FROM StagingDatabase.staging.stage_dim_product;

--This statement inserts attribute vales into dimension d_customer table
INSERT INTO AdventureWorks_DW.star_schema.d_customer (customer_id, title, first_name, middle_name, last_name,
                                                      valid_from, valid_to)
SELECT *
FROM StagingDatabase.staging.stage_dim_customer;


-- ***************************************************************
-- ************ INSERTING FIXED DATA INTO FACT TABLES ************
-- ***************************************************************

--This statement inserts attribute values into staging fact table stage_f_sales
INSERT INTO StagingDatabase.staging.stage_f_sales(business_customer_id, business_product_id, business_order_date,
                                                  quantity, line_total)
    (SELECT C.CustomerID, P.ProductID, OrderDate, SOD.OrderQty, SOD.LineTotal
     FROM AdventureWorks2017.Sales.SalesOrderHeader SOH
              JOIN AdventureWorks2017.Sales.SalesOrderDetail SOD on SOH.SalesOrderID = SOD.SalesOrderID
              JOIN AdventureWorks2017.Sales.Customer C on SOH.CustomerID = C.CustomerID
              JOIN AdventureWorks2017.Production.Product P on SOD.ProductID = P.ProductID
     WHERE OnlineOrderFlag = 1);


-- *******************************************************************
-- ********************** LOOKUP SURROGATE KEYS **********************
-- *******************************************************************

--This statement extracts the customer_id from staging dimension table stage_dim_customer and assigns it to the
-- customer_id attribute in stage_f_sales table when the value is null
UPDATE StagingDatabase.staging.stage_f_sales
SET customer_id = (SELECT dimension_customer_id
                   FROM AdventureWorks_DW.star_schema.d_customer AS dim_C_id
                   WHERE dim_C_id.customer_id = business_customer_id)
WHERE customer_id IS NULL;

--This statement extracts the product_id from staging dimension table stage_dim_product and assigns it to the
-- product_id attribute in stage_f_sales table when the value is null
UPDATE StagingDatabase.staging.stage_f_sales
SET product_id = (SELECT dimension_product_id
                  FROM AdventureWorks_DW.star_schema.d_product AS dim_P_id
                  WHERE dim_P_id.product_id = business_product_id)
WHERE product_id IS NULL;

--This statement extracts the date_id from staging dimension table stage_dim_date and assigns it to the
-- date_id attribute in stage_f_sales table when the value is null
UPDATE StagingDatabase.staging.stage_f_sales
SET date_id = (SELECT dimension_date_id
               FROM AdventureWorks_DW.star_schema.d_date AS dim_D_id
               WHERE dim_D_id.date = business_order_date)
WHERE date_id IS NULL;


-- ******************************************************************************************
-- ********************** INSERT VALUES INTO DATA WAREHOUSE FACT TABLE **********************
-- ******************************************************************************************

INSERT INTO AdventureWorks_DW.star_schema.f_sales(customer_id, product_id, date_id, quantity, line_total)
SELECT customer_id, product_id, date_id, quantity, line_total
FROM StagingDatabase.staging.stage_f_sales;