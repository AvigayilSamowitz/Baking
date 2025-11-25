-- Baking business scenario T-SQL implementation
-- Creates the Orders table, inserts sample data, and generates requested reports.

-- Use a dedicated schema for clarity
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'baking')
    EXEC('CREATE SCHEMA baking');
GO

-- Drop and recreate the table for repeatable runs
IF OBJECT_ID('baking.Orders', 'U') IS NOT NULL
    DROP TABLE baking.Orders;
GO

CREATE TABLE baking.Orders (
    OrderId         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName    NVARCHAR(100) NOT NULL,
    Branch          NVARCHAR(50) NOT NULL,
    OrderDate       DATE NOT NULL,
    BaseFlavor      NVARCHAR(100) NOT NULL,
    ItemType        NVARCHAR(20) NOT NULL CHECK (ItemType IN ('Cake','Cupcake','Cookie')),
    Topping         NVARCHAR(100) NULL,
    PictureFlag     BIT NOT NULL DEFAULT 0,
    Specifics       NVARCHAR(400) NULL,
    Occasion        NVARCHAR(100) NOT NULL,
    Amount          INT NOT NULL CHECK (
                        (ItemType = 'Cookie'  AND Amount BETWEEN 24 AND 500) OR
                        (ItemType = 'Cupcake' AND Amount BETWEEN 12 AND 500) OR
                        (ItemType = 'Cake'    AND Amount >= 1)
                    ),
    PricePerItem AS (
        CASE ItemType
            WHEN 'Cake' THEN 50
                          + CASE WHEN BaseFlavor = 'Strawberry shortcake' THEN 5 ELSE 0 END
                          + CASE WHEN PictureFlag = 1 THEN 8 ELSE 0 END
            WHEN 'Cupcake' THEN 3
            WHEN 'Cookie'  THEN 3.5 + CASE WHEN PictureFlag = 1 THEN 1.5 ELSE 0 END
        END
    ) PERSISTED,
    OrderTotal AS (Amount * PricePerItem) PERSISTED,
    CONSTRAINT CK_Cupcake_No_Pictures CHECK (NOT (ItemType = 'Cupcake' AND PictureFlag = 1))
);
GO

-- Sample data inserts
INSERT INTO baking.Orders (CustomerName, Branch, OrderDate, BaseFlavor, ItemType, Topping, PictureFlag, Specifics, Occasion, Amount)
VALUES
('Chaim Green', 'Lakewood', '2022-01-04', 'Strawberry shortcake', 'Cake', NULL, 0, 'Please make sure they both look the same', 'Baby', 2),
('Rivky Shapiro', 'Lakewood', '2021-07-22', 'Chocolate', 'Cake', 'Caramel', 0, 'Write Happy birthday on cake', 'Birthday', 1),
('Leah Gross', 'Brooklyn', '2021-06-11', 'Sugar', 'Cookie', 'Royal icing', 1, 'Graduation cap shape of picture I emailed', 'Graduation', 70),
('Baruch Goldberg', 'Brooklyn', '2021-09-12', 'Sugar', 'Cookie', 'Royal icing', 0, 'Shape of a mask and write thank you for keeping everyone safe and company logo', 'Company logo', 500),
('Binyamin Stein', 'Lakewood', '2021-02-15', 'Vanilla', 'Cake', 'Chocolate', 1, 'Write Happy 85th birthday on bottom of the attached photo', 'Birthday', 3),
('Batsheva Golden', 'Lakewood', '2021-08-14', 'Chocolate peanut butter', 'Cake', 'Peanut butter', 1, 'Write Shloimy and the number 3 on pic', 'Birthday', 1),
('Rena Stern', 'Brooklyn', '2021-10-11', 'Sugar', 'Cookie', 'Fondant', 0, 'Pink background with glitter and shape of balloon with word Sori', 'Bas mitzvah', 75),
('Layala Katz', 'Lakewood', '2021-09-05', 'Vanilla', 'Cupcake', 'Strawberry', 0, 'Make it look nice!', 'Birthday', 28),
('Sara Leah Levy', 'Brooklyn', '2021-05-18', 'Vanilla', 'Cupcake', 'Coconut', 0, 'none', 'Engagement', 100),
('Devorah Friedman', 'Brooklyn', '2021-07-04', 'Strawberry shortcake', 'Cake', NULL, 0, 'none', 'Wedding', 15),
('Kaufman', 'Lakewood', '2021-11-09', 'Chocolate peanut butter', 'Cake', 'Chocolate', 0, 'none', 'Bar mitzvah', 3),
('Chana Cohen', 'Lakewood', '2021-07-04', 'Banana', 'Cake', 'Vanilla', 1, 'Attached photo', 'Anniversary', 1),
('Ahuva Licht', 'Lakewood', '2021-06-22', 'Sugar', 'Cookie', 'Royal icing', 0, 'Write Chaim and Devorah', 'Engagement', 75),
('Tziporah Markowitz', 'Lakewood', '2021-03-16', 'Strawberry shortcake', 'Cake', NULL, 0, 'no', 'Baby', 3),
('David Fried', 'Lakewood', '2021-10-01', 'Chocolate peanut butter', 'Cake', 'Chocolate', 0, 'no', 'Bar mitzvah', 2),
('Moshe Abrams', 'Brooklyn', '2021-08-23', 'Vanilla', 'Cupcake', 'Peanut butter', 0, 'Write 3 on it', 'Birthday', 150),
('Rachel Bernstein', 'Lakewood', '2021-02-28', 'Sugar', 'Cookie', 'Fondant', 1, 'Attached photo of daughter', 'Bas mitzvah', 80),
('Faiga Berg', 'Brooklyn', '2021-10-12', 'Chocolate', 'Cupcake', 'Chocolate', 0, 'Add a pecan on each one', 'Event', 350),
('Dena Bergman', 'Brooklyn', '2021-06-08', 'Sugar', 'Cookie', 'Royal icing', 0, 'Write Shimon and Leah', 'Engagement', 75),
('Asher Yechiel Eisen', 'Brooklyn', '2021-12-31', 'Sugar', 'Cookie', 'Royal icing', 0, 'In shape of thirteen', 'Bar mitzvah', 175),
('Mendy Fischer', 'Lakewood', '2021-07-04', 'Banana', 'Cupcake', 'Vanilla', 0, 'For new baby', 'Baby', 100),
('Chaya Kaplan', 'Lakewood', '2021-01-01', 'Chocolate', 'Cupcake', 'Vanilla', 0, 'Make it taste great please', 'Birthday', 100),
('Sarala Schwartz', 'Brooklyn', '2021-06-09', 'Chocolate', 'Cupcake', 'Vanilla', 0, 'none', 'Baby', 50),
('Sarah Braunstein', 'Brooklyn', '2021-10-24', 'Sugar', 'Cookie', 'Royal icing', 1, 'See attached picture of my house', 'Family party', 110);
GO

-- 1) Sum of how many of each type of product is sold per branch (grouped by item and base flavor)
SELECT
    Branch,
    ItemType,
    BaseFlavor,
    SUM(Amount) AS TotalQuantity
FROM baking.Orders
GROUP BY Branch, ItemType, BaseFlavor
ORDER BY Branch, ItemType, BaseFlavor;
GO

-- 2) Orders per season, event, and branch
WITH Seasoned AS (
    SELECT *,
           CASE
                WHEN MONTH(OrderDate) IN (7,8) THEN 'Summer'
                WHEN MONTH(OrderDate) IN (9,10) THEN 'Holiday time'
                WHEN MONTH(OrderDate) BETWEEN 11 AND 12 OR MONTH(OrderDate) BETWEEN 1 AND 4 THEN 'Winter'
                WHEN MONTH(OrderDate) IN (5,6) THEN 'Spring'
           END AS Season
    FROM baking.Orders
)
SELECT Season, Occasion AS Event, Branch, COUNT(*) AS Orders
FROM Seasoned
GROUP BY Season, Occasion, Branch
ORDER BY Season, Occasion, Branch;
GO

-- 3) Money received each month per branch
SELECT
    Branch,
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
    SUM(OrderTotal) AS Revenue
FROM baking.Orders
GROUP BY Branch, DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY Branch, OrderMonth;
GO

-- 4) Order counts each month per branch
SELECT
    Branch,
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
    COUNT(*) AS Orders
FROM baking.Orders
GROUP BY Branch, DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY Branch, OrderMonth;
GO

-- Bonus: earliest order date
SELECT MIN(OrderDate) AS EarliestOrderDate FROM baking.Orders;
GO
