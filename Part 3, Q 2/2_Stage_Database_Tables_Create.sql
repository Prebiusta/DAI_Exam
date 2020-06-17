-- ***********************************************
-- ************ CREATING STAGE TABLES ************
-- ***********************************************
--This statement creates staging dimension table stage_dim_customer with attributes and assigned
-- primary key as customer_id
CREATE TABLE StagingDatabase.staging.stage_dim_customer
(
    customer_id INT NOT NULL,
    title       varchar(10),
    first_name  varchar(50),
    middle_name varchar(50),
    last_name   varchar(50),
    valid_from  DATETIME,
    valid_to    DATETIME,
);
--This statement creates staging dimension table stage_dim_product with attributes and assigned
-- primary key as dimension_product_id
CREATE TABLE StagingDatabase.staging.stage_dim_product
(
    product_id     INT,
    price_range_id INT,
    name           varchar(50),
    price          DECIMAL(10, 2),
    valid_from     DATETIME,
    valid_to       DATETIME,
);

-- Create a table which holds last update variable
CREATE TABLE StagingDatabase.staging.LastUpdate
(
    lastUpdate DATETIME DEFAULT GETDATE()
);

-- Inset value into LastUpdate table
INSERT INTO StagingDatabase.staging.LastUpdate(lastUpdate)
VALUES (GETDATE());

--This statement creates staging fact table stage_f_sales with attributes and assigned primary key as sales_id
CREATE TABLE StagingDatabase.staging.stage_f_sales
(
    customer_id          INT      NULL,
    product_id           INT      NULL,
    date_id              INT      NULL,
    business_customer_id INT      NULL,
    business_product_id  INT      NULL,
    business_order_date  DATETIME NULL,
    quantity             INT      NULL,
    line_total           FLOAT    NULL,
);

-- Create temporary table for f_sales.
CREATE TABLE StagingDatabase.staging.temp_f_sales
(
    customer_id          INT      NULL,
    product_id           INT      NULL,
    date_id              INT      NULL,
    business_customer_id INT      NULL,
    business_product_id  INT      NULL,
    business_order_date  DATETIME NULL,
    quantity             INT      NULL,
    line_total           FLOAT    NULL,
);

-- Create temporary table to store added products so we can handle valid_to attribute
CREATE TABLE StagingDatabase.staging.stage_dim_product_added
(
    product_id     INT,
    price_range_id INT,
    name           varchar(50),
    price          DECIMAL(10, 2),
    valid_from     DATETIME,
    valid_to       DATETIME,
);

-- Create temporary table to store updated products so we can handle valid_to attribute and
-- deleting old products
CREATE TABLE StagingDatabase.staging.stage_dim_product_changed
(
    product_id     INT,
    price_range_id INT,
    name           varchar(50),
    price          DECIMAL(10, 2),
    valid_from     DATETIME,
    valid_to       DATETIME,
);

-- Create temporary table to store updated customers so we can handle valid_to attribute and
-- deleting old customers
CREATE TABLE StagingDatabase.staging.stage_dim_customer_changed
(
    customer_id INT,
    title       varchar(10),
    first_name  varchar(50),
    middle_name varchar(50),
    last_name   varchar(50),
    valid_from  DATETIME,
    valid_to    DATETIME,

);
-- Create temporary table to store added customers so we can handle valid_to attribute
CREATE TABLE StagingDatabase.staging.stage_dim_customer_added
(
    customer_id INT,
    title       varchar(10),
    first_name  varchar(50),
    middle_name varchar(50),
    last_name   varchar(50),
    valid_from  DATETIME,
    valid_to    DATETIME,

);


