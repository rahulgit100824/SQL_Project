--Creating Database

CREATE DATABASE Ecommerce_Orders;

USE Ecommerce_Orders;

--Importing csv Files Datasets
--Customers.csv, OrderItems, Orders, and Payments

--Creating Relationships

ALTER TABLE Customers ADD PRIMARY KEY (customer_id)
ALTER TABLE Orders ADD FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
ALTER TABLE Orders ADD PRIMARY KEY (order_id)
ALTER TABLE OrderItems ADD FOREIGN KEY (order_id) REFERENCES Orders (order_id)
ALTER TABLE Payments ADD FOREIGN KEY (order_id) REFERENCES Orders (order_id)

--Customer_id FROM Customers table and Order_id FROM Orders table are primary key no duplicate
--values or null value will be inserted, however customer_id FROM orders and order_id FROM 
--Payments and OrderItems table must set unique and not null as they are linked to foreign keys.

ALTER TABLE orders ADD CONSTRAINT unique_customerid UNIQUE (customer_id)
ALTER TABLE payments ADD CONSTRAINT unique_order_id_ptm UNIQUE (order_id)
ALTER TABLE OrderItems ADD CONSTRAINT unique_order_id_orderitm UNIQUE (order_id)

--Total Sales
SELECT ROUND(SUM(payment_value),0) AS total_sales FROM Payments

--Total Profit
SELECT SUM(profit) as total_profit FROM Payments

--Total Product Count
SELECT COUNT(distinct product_category_name) FROM OrderItems

--1. Customer Segmentation and Behavior Analysis:

--Distribution of Customer across state

SELECT customer_state, COUNT(customer_id)
total_customer FROM Customers
GROUP BY customer_state
ORDER BY total_customer DESC

-- Preferred Payment Methods

SELECT payment_type, COUNT(product_id) AS Payment_Method
FROM OrderItems
JOIN Payments
ON OrderItems.order_id=Payments.order_id
GROUP BYpayment_type
ORDER BY Payment_Method DESC

--Installment patterns for high-value items

SELECT payment_installments, COUNT(product_id) AS total_orders
FROM Payments
JOIN OrderItems
ON Payments.order_id=OrderItems.order_id
WHERE price > 1000 -- AsSUMing high-value items are those above 1000
GROUP BY payment_installments
ORDER BY total_orders DESC;

--PROFIT ANALYSIS
--States that generates most profit

SELECT customer_state, ROUND(SUM(profit),2) AS total_profit
FROM Customers
JOIN orders
ON Customers.customer_id=Orders.customer_id
JOIN Payments
ON Orders.order_id=Payments.order_id
GROUP BY customer_state
ORDER BY total_revenue DESC;

--Profit by product category

SELECT product_category_name, ROUND(SUM(profit),2) AS total_profit
FROM OrderItems
JOIN Payments
ON OrderItems.order_id=Payments.order_id
GROUP BY product_category_name
ORDER BY total_profit DESC;

--Profit by Each Year and Quarter
SELECT Profit_Year, Quarter, sum(profit) as Total_profit from (
SELECT Year(order_purchase_timestamp) as Profit_Year,
    CASE 
        WHEN MONTH(order_purchase_timestamp) IN (1, 2, 3) THEN 'Qtr1'
        WHEN MONTH(order_purchase_timestamp) IN (5, 5, 6) THEN 'Qtr2'
        WHEN MONTH(order_purchase_timestamp) IN (7, 8, 9) THEN 'Qtr3'
        ELSE 'Qtr4'
    END AS Quarter,
    profit
FROM Orders
JOIN Payments 
    ON Orders.order_id = Payments.order_id) as year_qtr_wise_profit
GROUP BY Profit_Year, Quarter
ORDER BY Profit_Year, Quarter



--SALES ANALYSIS

--Sales by Product Category

SELECT product_category_name, ROUND(SUM(payment_value),2) AS total_sales
FROM OrderItems
JOIN Payments
ON OrderItems.order_id=Payments.order_id
GROUP BY product_category_name
ORDER BY total_sales DESC;

--States with highest number of orders

SELECT customer_state, ROUND(SUM(Payments.payment_value),2) AS total_orders
FROM Customers
JOIN Orders
ON Customers.customer_id=Orders.customer_id
JOIN Payments
ON Orders.order_id=Payments.order_id
GROUP BY customer_state
ORDER BY total_orders DESC;

--Sales each Quater
SELECT 
    Quater, 
    SUM(payment_value) AS Quater_sale
FROM 
(
    SELECT 
        CASE 
            WHEN MONTH(order_purchase_timestamp) IN (1, 2, 3) THEN 'Qtr1'
            WHEN MONTH(order_purchase_timestamp) IN (4, 5, 6) THEN 'Qtr2'
            WHEN MONTH(order_purchase_timestamp) IN (7, 8, 9) THEN 'Qtr3'
            ELSE 'Qtr4'
        END AS Quater,
        payment_value
    FROM Orders
    JOIN Payments 
        ON Orders.order_id = Payments.order_id
) AS SubQueryAlias
GROUP BY Quater
ORDER BY Quater;


--PERFORMANCE OF PRODUCT SELLER

-- Top 5 Seller by revenue
SELECT TOP 5(seller_id), ROUND(SUM(payment_value),2) AS total_sales
FROM OrderItems
JOIN Payments
ON OrderItems.order_id=Payments.order_id
GROUP BY seller_id
ORDER BY total_sales DESC;

--Top product across states
WITH RankedProducts AS (
    SELECT customer_state, product_category_name,
        COUNT(product_category_name) AS product_COUNT,
        RANK() OVER (PARTITION BY customer_state ORDER BY COUNT(product_category_name) DESC) AS ranking
    FROM Customers
        JOIN Orders ON Customers.customer_id = Orders.customer_id
        JOIN OrderItems ON Orders.order_id = OrderItems.order_id
    GROUP BY customer_state, product_category_name
)
SELECT customer_state, product_category_name, product_COUNT, ranking
FROM RankedProducts
WHERE ranking = 1
ORDER BY product_COUNT desc;

--TIME SERIES FORECASTING

--Sales and Orders trend over time

SELECT FORMAT(order_purchase_timestamp, 'yyyy-MM') AS month,
	COUNT(product_id) AS total_orders, ROUND(SUM(payment_value),2) AS total_sales
FROM Orders
JOIN OrderItems
ON Orders.order_id=OrderItems.order_id
JOIN Payments
ON orderitems.order_id=Payments.order_id
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY FORMAT(order_purchase_timestamp, 'yyyy-MM');


SELECT * FROM order_trend
SELECT * FROM predit_future_sale
SELECT * FROM preferred_payment_type
SELECT * FROM revenue_by_category
SELECT * FROM sales_by_category where product_category_name = 'toys'
SELECT * FROM sales_by_state
SELECT * FROM seasonal_sale
SELECT * FROM shipping_cost_by_product_dimention
SELECT * FROM top_seller
SELECT * FROM total_order_by_state where customer_state = 'SP'
SELECT * FROM total_revenue_by_state

--Profit change over quater to quater

WITH QoQ AS(
SELECT 
    Quater, 
    SUM(profit) AS profit_quater
FROM 
    (
        SELECT Year(order_purchase_timestamp) as Profit_Year,

            CASE 
                WHEN MONTH(order_purchase_timestamp) IN (1, 2, 3) THEN 'Qtr1'
                WHEN MONTH(order_purchase_timestamp) IN (5, 5, 6) THEN 'Qtr2'
                WHEN MONTH(order_purchase_timestamp) IN (7, 8, 9) THEN 'Qtr3'
                ELSE 'Qtr4'
            END AS Quater,
            profit
        FROM Orders
        JOIN Payments 
            ON Orders.order_id = Payments.order_id where Year(order_purchase_timestamp) = 2018
    ) AS Quater_Profit
GROUP BY Quater
)
SELECT quater, profit_quater,
case
WHEN ROUND(LAG(profit_quater) OVER(ORDER BY quater),2) is NULL THEN 0
ELSE ROUND(LAG(profit_quater) OVER(ORDER BY quater),2) END AS previous_profit,
case
WHEN ROUND((profit_quater - LAG(profit_quater) OVER(ORDER BY quater))/LAG(profit_quater) OVER(ORDER BY quater),2) is NULL THEN 0 
ELSE
ROUND((profit_quater - LAG(profit_quater) OVER(ORDER BY quater))/LAG(profit_quater) OVER(ORDER BY quater),2) END AS qoq_per_change FROM QoQ;
