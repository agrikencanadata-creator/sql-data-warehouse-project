/*
================================================================================================
Product Report
================================================================================================
Purpose:
	- This report consolidates key product metrics and behaviors

Highlights:
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Segments products by revenue to identify High-performers, Mid-range, or Low-performers.
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total unique customers
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
================================================================================================
*/


/*
------------------------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------------------------------------------------
*/
WITH base_query AS
(
SELECT
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_number,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
WHERE order_date IS NOT NULL								-- Only consider valid sales dates
)

/*
------------------------------------------------------------------------------------------------
3) Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total unique customers
		- lifespan (in months)
------------------------------------------------------------------------------------------------
*/



SELECT
	p.product_key,
	p.product_number,
	p.product_name,
