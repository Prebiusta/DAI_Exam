CREATE TABLE StagingDatabase.staging.d_current_price
(
    d_current_price_id INT IDENTITY,
    start_price        decimal(10,2),
    end_price          decimal(10,2),
    PRIMARY KEY (d_current_price_id)
);

DECLARE @StartPrice decimal(10,2) = 0.00;
DECLARE @EndPrice decimal(10,2) = 200.00;
DECLARE @Increment decimal(10,2) = 200.00;

DECLARE @MaxPrice decimal(10,2) = (SELECT MAX(ListPrice)
                           FROM AdventureWorks2017.Production.Product);

WHILE @EndPrice <= @MaxPrice
    BEGIN
        INSERT INTO StagingDatabase.staging.d_current_price (start_price, end_price) VALUES (
                                                                     @StartPrice,
                                                                     @EndPrice
                                                                    );
        SET @StartPrice = @StartPrice + @Increment;
        SET @EndPrice = @EndPrice + @Increment;
    END