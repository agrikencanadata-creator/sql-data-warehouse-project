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

-- Calculate the running total of sales over time which is partitioned by year
-- The running total of sales will be summed up only within the same year over time

-- monthly basis
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales			-- Window Function
	AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_avg_price						-- Window Function
FROM
	(
	SELECT
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
	)t;
GO

-- yearly basis
SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales			-- Window Function
	AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_avg_price						-- Window Function
FROM
	(
	SELECT
		DATETRUNC(YEAR, order_date) AS order_year,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(YEAR, order_date)
	)t;
GO

/*
Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year sales
*/
WITH yearly_product_sales AS
(
SELECT
	YEAR (f.order_date) AS order_year,
	p.product_name,
	SUM (f.sales_amount) AS current_sales
FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
-- ORDER BY YEAR(f.order_date), p.product_name
)

SELECT
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg_sales,
	CASE
		 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
 		 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
		 ELSE 'avg'
	END AS avg_change,
	-- Year-over-year Analysis
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS py_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS diff_py_sales,
	CASE
		 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) > 0 THEN 'Increase'
		 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) < 0 THEN 'Decrease'
		 ELSE 'No Change'	
	END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year



