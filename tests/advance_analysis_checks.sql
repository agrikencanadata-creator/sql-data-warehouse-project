-- Check the trend of changes over years
-- it brings insights on high-level overview that helps with strategic decision-making process

-- Yearly time parameter is displayed as INT type 
SELECT
YEAR(order_date) AS order_year,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date) ASC;
GO

-- Monthly time parameter is displayed as INT type 
SELECT
MONTH(order_date) AS order_month,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date) ASC;
GO

-- Yearly and monthly time parameter is displayed as INT type 
SELECT
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date) ASC;
GO

-- Monthly time parameter is displayed as DATE type 
SELECT
DATETRUNC(MONTH, order_date) AS order_date,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date) ASC;
GO

-- Yearly time parameter is displayed as DATE type 
SELECT
DATETRUNC(YEAR, order_date) AS order_date,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR, order_date)
ORDER BY DATETRUNC(YEAR, order_date) ASC;
GO

-- Yearly and monthly time parameter is displayed as STRING type 
SELECT
FORMAT(order_date,'yyyy_MMM') AS order_date,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy_MMM')
ORDER BY FORMAT(order_date,'yyyy_MMM') ASC;
GO

===============================================================
Cumulative Analysis
===============================================================
-- Calculate the total sales per month
-- Calculate the running total of sales over time
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales			-- Window Function
FROM
(SELECT
DATETRUNC(MONTH, order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date))t;
GO
