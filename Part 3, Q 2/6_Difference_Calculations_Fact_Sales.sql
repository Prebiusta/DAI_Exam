-- ***********************************************************************************************
-- ************************************* FACT TABLE UPDATE ***************************************
-- ***********************************************************************************************

DECLARE @LAST_UPDATE as DATETIME = (SELECT lastUpdate
                                    FROM StagingDatabase.staging.LastUpdate);

-- Insert newly updated rows into temp_f_sales table. Select only the ones newer than the last update.
INSERT INTO StagingDatabase.staging.stage_f_sales
(business_customer_id, business_product_id, business_order_date, quantity, line_total)
    (SELECT C.CustomerID, P.ProductID, OrderDate, SOD.OrderQty, SOD.LineTotal
     FROM AdventureWorks2017.Sales.SalesOrderHeader SOH
              JOIN AdventureWorks2017.Sales.SalesOrderDetail SOD on SOH.SalesOrderID = SOD.SalesOrderID
              JOIN AdventureWorks2017.Sales.Customer C on SOH.CustomerID = C.CustomerID
              JOIN AdventureWorks2017.Production.Product P on SOD.ProductID = P.ProductID
     WHERE OnlineOrderFlag = 1
       AND OrderDate > @LAST_UPDATE);

-- Find corresponding surrogate keys.
-- ***************************** Customer *****************************
UPDATE StagingDatabase.staging.stage_f_sales
SET customer_id = (SELECT dimension_customer_id
                   FROM AdventureWorks_DW.star_schema.d_customer AS dim_C_id
                   WHERE dim_C_id.customer_id = business_customer_id
                     AND valid_to = '9999-12-31')
WHERE customer_id IS NULL;

-- ***************************** Product *****************************
UPDATE StagingDatabase.staging.stage_f_sales
SET product_id = (SELECT dimension_product_id
                  FROM AdventureWorks_DW.star_schema.d_product AS dim_P_id
                  WHERE dim_P_id.product_id = business_product_id
                    AND valid_to = '9999-12-31')
WHERE product_id IS NULL;

-- ***************************** Date *****************************
UPDATE StagingDatabase.staging.stage_f_sales
SET date_id = (SELECT dimension_date_id
               FROM AdventureWorks_DW.star_schema.d_date AS dim_D_id
               WHERE dim_D_id.date = business_order_date)
WHERE date_id IS NULL;

-- Insert data into Data Warehouse Fact Sales table
INSERT INTO AdventureWorks_DW.star_schema.f_sales(customer_id, product_id, date_id, quantity, line_total)
SELECT customer_id, product_id, date_id, quantity, line_total
FROM StagingDatabase.staging.temp_f_sales;

-- Update last update table with the newest date
UPDATE StagingDatabase.staging.LastUpdate
SET lastUpdate = GETDATE()
WHERE lastUpdate = @LAST_UPDATE;