CREATE DATABASE Ecommerce_Orders;

USE ecommerce_orders;

CREATE TABLE Customers (
customer_id VARCHAR(100) PRIMARY KEY,
customer_zip_code_prefix INT,
customer_city VARCHAR(50),
customer_state VARCHAR(50)
);

CREATE TABLE Orders (
order_id VARCHAR(50) PRIMARY KEY,
customer_id VARCHAR(50) UNIQUE,
order_purchase_timestamp  DATE,
order_approved_at DATE,
CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Payments (
order_id VARCHAR(50) UNIQUE,
payment_sequential INT,
payment_type VARCHAR(50),
payment_installments INT,
payment_value FLOAT,
profit FLOAT,
CONSTRAINT fk_Orders FOREIGN KEY (order_id) REFERENCES Orders (order_id)
);

CREATE TABLE OrderItems (
order_id VARCHAR(50) UNIQUE,
product_id VARCHAR(50),
seller_id VARCHAR(50),
product_category_name VARCHAR (50),
price FLOAT,
shipping_charges FLOAT,
product_weight_g FLOAT,
product_length_cm FLOAT,
product_height_cm FLOAT,
product_width_cm FLOAT,
CONSTRAINT fk_Ordersi FOREIGN KEY (order_id) REFERENCES Orders (order_id)
);

INSERT INTO Customers (customer_id, customer_zip_code_prefix, customer_city, customer_state) VALUES
("I74lXDOfoqsp",6020,"goiania","GO");

INSERT INTO Orders (order_id, customer_id, order_purchase_timestamp, order_approved_at) VALUES
("u6rPMRAYIGig","I74lXDOfoqsp","2017-11-18","2017-11-18");

INSERT INTO Payments (order_id, payment_sequential, payment_type, payment_installments, payment_value, profit) VALUES
("u6rPMRAYIGig",1,"credit_card",2,155.77,18.69);

INSERT INTO OrderItems (order_id,product_id,seller_id,product_category_name,
price,shipping_charges,product_weight_g,product_length_cm,
product_height_cm,product_width_cm) VALUES
("u6rPMRAYIGig","1slxdgbgWFax","3jwvL6ihC45G","toys",24.1,20.9,50,16,5,11);

-- TOTAL SALES
SELECT ROUND(SUM(payment_value),0) AS total_sales FROM Payments

-- TOTAL PROFIT
SELECT SUM(profit) as total_profit FROM Payments

-- TOTAL PRODUCT COUNT
SELECT COUNT(distinct product_category_name) FROM OrderItems

-- Distribution of Customer across state

SELECT customer_state, COUNT(customer_id)
    total_customer
    FROM Customers
GROUP BY customer_state
ORDER BY total_customer DESC

-- Preferred Payment Method

SELECT payment_type, COUNT(product_id)
	AS Payment_Method
	FROM OrderItems
JOIN Payments ON OrderItems.order_id=Payments.order_id
GROUP BY payment_type
ORDER BY Payment_Method DESC;

-- Installment patterns for high-value items

SELECT payment_installments, COUNT(product_id) AS total_orders
   FROM Payments
JOIN OrderItems
   ON Payments.order_id=OrderItems.order_id
WHERE price > 1000 
GROUP BY payment_installments
ORDER BY total_orders DESC;

-- States that generates most profit

SELECT customer_state, ROUND(SUM(profit),2) AS total_profit
   FROM Customers
JOIN orders
   ON Customers.customer_id=Orders.customer_id
JOIN Payments
   ON Orders.order_id=Payments.order_id
GROUP BY customer_state
ORDER BY total_profit DESC;

-- Profit by product category

SELECT product_category_name, ROUND(SUM(profit),2) AS total_profit
   FROM OrderItems
JOIN Payments
   ON OrderItems.order_id=Payments.order_id
GROUP BY product_category_name
ORDER BY total_profit DESC;

-- Profit by Each Year and Quarter

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

-- Sales by Product Category

SELECT product_category_name, ROUND(SUM(payment_value),2) AS total_sales
   FROM OrderItems
JOIN Payments
   ON OrderItems.order_id=Payments.order_id
GROUP BY product_category_name
ORDER BY total_sales DESC;

-- States with high sales

SELECT customer_state, round(sum(payments.payment_value),2) AS total_sales
   FROM Customers
JOIN Orders
   ON Customers.customer_id=Orders.customer_id
JOIN payments
   ON Orders.order_id=payments.order_id
GROUP BY customer_state
ORDER BY total_sales DESC;

-- Sales by Each Quarter

SELECT Quarter, SUM(payment_value) AS
Quarter_sale FROM 
(
  SELECT CASE 
   WHEN MONTH(order_purchase_timestamp)
		IN (1, 2, 3) THEN 'Qtr1'
   WHEN MONTH(order_purchase_timestamp)
		IN (4, 5, 6) THEN 'Qtr2'
   WHEN MONTH(order_purchase_timestamp)
		IN (7, 8, 9) THEN 'Qtr3'
   ELSE 'Qtr4' END AS Quarter, payment_value
    FROM Orders
    JOIN Payments ON Orders.order_id =
Payments.order_id
) AS Subquery
GROUP BY Quarter ORDER BY Quarter;

-- Top 5 Seller by Sales

SELECT seller_id, ROUND(SUM(payment_value),2) AS total_sales
   FROM OrderItems
JOIN Payments
   ON OrderItems.order_id=Payments.order_id
GROUP BY seller_id
ORDER BY total_sales DESC
LIMIT 5;

-- TOP PRODUCT ACROSS STATES

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
ORDER BY product_COUNT desc;

-- Sales and Orders trend over time

SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%m/%Y') AS month, 
    COUNT(DISTINCT OrderItems.product_id) AS total_orders, 
    ROUND(SUM(Payments.payment_value), 2) AS total_sales
FROM Orders
JOIN OrderItems
	ON Orders.order_id = OrderItems.order_id
JOIN Payments
	ON OrderItems.order_id = Payments.order_id 
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%m/%Y')
ORDER BY DATE_FORMAT(order_purchase_timestamp, '%m/%Y');

SELECT * FROM total_sales
SELECT * FROM total_profit
SELECT * FROM product_count
SELECT * FROM customer_across_state
SELECT * FROM preferred_payment
SELECT * FROM installment_pattern
SELECT * FROM most_profit
SELECT * FROM profit_product_category
SELECT * FROM profit_y_and_q
SELECT * FROM Sales_product_cat
SELECT * FROM highest_order
SELECT * FROM sales_quater
SELECT * FROM top_seller
SELECT * FROM top_product;
drop view top_product;
SELECT * FROM sales_order_trend
