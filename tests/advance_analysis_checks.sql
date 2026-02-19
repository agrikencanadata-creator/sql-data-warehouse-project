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

-- Part-to-whole Analysis
-- Identify categories
WITH category_sales AS
(
SELECT 
	category,
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
GROUP BY category
)

SELECT
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND(100 * (CAST (total_sales AS FLOAT) / SUM(total_sales) OVER()),2),'%') AS percenteage_of_total_sales
FROM category_sales
ORDER BY total_sales DESC

/*Segment products into cost range and
count how many products fall into each segment
*/
-- Order by cost range class
WITH product_segment AS
(
SELECT 
	product_key,
	product_name,
	cost,
	CASE
		 WHEN cost < 100				THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500	THEN '100 - 500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
		 ELSE 'Above 1000'
	END AS cost_range
FROM gold.dim_products
),

class AS
(
SELECT
	product_key,
	product_name,
	cost,
	cost_range,
	CASE
		 WHEN cost_range = 'Below 100'	THEN 1
		 WHEN cost_range = '100 - 500'	THEN 2
		 WHEN cost_range = '500 - 1000'	THEN 3
		 ELSE 4
	END AS cost_range_class
FROM product_segment
)


SELECT
	cost_range_class,
	cost_range,
 	COUNT(product_key) AS total_products
FROM class
GROUP BY cost_range_class, cost_range
ORDER BY cost_range_class;
GO

/*Segment products into cost range and
count how many products fall into each segment
*/
-- Order by total products
WITH product_segment AS
(
SELECT 
	product_key,
	product_name,
	cost,
	CASE
		 WHEN cost < 100				THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500	THEN '100 - 500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
		 ELSE 'Above 1000'
	END AS cost_range
FROM gold.dim_products
),

class AS
(
SELECT
	product_key,
	product_name,
	cost,
	cost_range,
	CASE
		 WHEN cost_range = 'Below 100'	THEN 1
		 WHEN cost_range = '100 - 500'	THEN 2
		 WHEN cost_range = '500 - 1000'	THEN 3
		 ELSE 4
	END AS cost_range_class
FROM product_segment
)


SELECT
	cost_range,
 	COUNT(product_key) AS total_products
FROM class
GROUP BY cost_range
ORDER BY total_products DESC

/*
Group customers into three segments based on their spending behavior:
	- VIP: customers with at least 12 months of history and spending more than 5000 Euro
	- Regular: customers with at least 12 months of history and spending 5000 Euro or less
	- New: customers with a lifespan less than 12 months
and find the total number of customers by each group
*/

-- Approach: cte + subquery
WITH customer_spending AS
(
SELECT
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)

SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM
(
	SELECT
		customer_key,
		total_spending,
		lifespan,
		CASE
			 WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
			 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
			 ELSE 'New'
		END AS customer_segment
	FROM customer_spending
)t
GROUP BY customer_segment
ORDER BY total_customers DESC;
GO

/*
Group customers into three segments based on their spending behavior:
	- VIP: customers with at least 12 months of history and spending more than 5000 Euro
	- Regular: customers with at least 12 months of history and spending 5000 Euro or less
	- New: customers with a lifespan less than 12 months
and find the total number of customers by each group
*/

-- Approach: cte + cte
WITH customer_spending AS
(
SELECT
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
GROUP BY c.customer_key
),

segment AS
(
SELECT
	customer_key,
	total_spending,
	lifespan,
	CASE
		 WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment
FROM customer_spending
)

SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM segment
GROUP BY customer_segment
ORDER BY total_customers DESC;
GO



