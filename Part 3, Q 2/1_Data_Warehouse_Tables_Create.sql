--This statement creates dimension table d_customer with attributes and primary key is assigned to dimension_customer_id

CREATE TABLE AdventureWorks_DW.star_schema.d_customer
(
    dimension_customer_id INT         NOT NULL IDENTITY,
    customer_id           INT         NOT NULL,
    title                 varchar(10) NOT NULL,
    first_name            varchar(50) NOT NULL,
    middle_name           varchar(50) NOT NULL,
    last_name             varchar(50) NOT NULL,
    valid_from            DATETIME    NOT NULL,
    valid_to              DATETIME    NOT NULL,
    PRIMARY KEY (dimension_customer_id)
);

CREATE TABLE AdventureWorks_DW.star_schema.d_price_range
(
    dimension_price_range_id INT IDENTITY,
    start_price              decimal(10, 2),
    end_price                decimal(10, 2),
    PRIMARY KEY (dimension_price_range_id)
);

--This statement creates dimension table d_product with attributes and primary key is assigned to dimension_product_id
CREATE TABLE AdventureWorks_DW.star_schema.d_product
(
    dimension_product_id INT         NOT NULL IDENTITY,
    product_id           INT         NOT NULL,
    price_range_id       INT         NOT NULL,
    name                 varchar(50) NOT NULL,
    valid_from           DATETIME    NOT NULL,
    valid_to             DATETIME    NOT NULL,
    PRIMARY KEY (dimension_product_id),
    FOREIGN KEY (price_range_id) REFERENCES AdventureWorks_DW.star_schema.d_price_range (dimension_price_range_id)
);
--This statement creates dimension table d_date with attributes and primary key is assigned to dimension_date_id
CREATE TABLE AdventureWorks_DW.star_schema.d_date
(
    dimension_date_id INT         NOT NULL IDENTITY,
    month_name        varchar(10) NOT NULL,
    day_name          varchar(10) NOT NULL,
    date              date        NOT NULL,
    PRIMARY KEY (dimension_date_id)
);

--This statement creates fact table f_sales with attributes, primary key is assigned to sales_id and foreign keys customer_id, product_id
CREATE TABLE AdventureWorks_DW.star_schema.f_sales
(
    sales_id    INT NOT NULL IDENTITY,
    customer_id INT NOT NULL,
    product_id  INT NOT NULL,
    date_id     INT NOT NULL,
    quantity    INT NOT NULL,
    line_total  INT NOT NULL,
    PRIMARY KEY (sales_id),
    FOREIGN KEY (customer_id) REFERENCES AdventureWorks_DW.star_schema.d_customer (dimension_customer_id),
    FOREIGN KEY (product_id) REFERENCES AdventureWorks_DW.star_schema.d_product (dimension_product_id),
    FOREIGN KEY (date_id) REFERENCES AdventureWorks_DW.star_schema.d_date (dimension_date_id)
);
