/*
Below are test to check the count number of cst_id in
	bronze.crm_cust_info : 18493
	silver.crm_cust_info : 18484
*/

select 
*
from gold.dim_customers
where	customer_number = 'AW00011562'
or		customer_number = 'AW00011912'

---------------------------------------------------------------------------------------

select 
*
from gold.fact_sales

---------------------------------------------------------------------------------------

select
*
from silver.crm_cust_info
where cst_key = 'AW00029483'

---------------------------------------------------------------------------------------

select
count(count_cst_id)
from
(
select
	cst_id,
	COUNT(cst_id) as count_cst_id
from silver.crm_cust_info
group by cst_id
-- having COUNT(cst_id) > 1 or cst_id is NULL
)t

---------------------------------------------------------------------------------------
/*to calculate count of cst_id
in which the display is only showing count that has value of 1 or cst_id is not null*/

select
count(count_cst_id)
from
(
select
	cst_id,
	--COUNT(cst_id) as count_cst_id,
	COUNT(*) as count_cst_id
from bronze.crm_cust_info
-- where cst_id is not null
group by cst_id
-- having COUNT(cst_id) = 1 or cst_id is not NULL
having COUNT(cst_id) <> 1 or cst_id is NULL
)t

---------------------------------------------------------------------------------------
/*
select
*
from bronze.crm_cust_info
-- where cst_id is null
where cst_id is not null
*/

select
	cst_id,
	count(*)
from bronze.crm_cust_info
-- where cst_id is not null
group by cst_id
-- having count(*) > 1 or cst_id is null
having count(*) = 1 or cst_id is not null

---------------------------------------------------------------------------------------

select
*
from
(
select
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
from bronze.crm_cust_info
where cst_id is not null
)t
where flag_last = 1

---------------------------------------------------------------------------------------

with base_query as
(
select
	cst_id,
	count_cst_id
from
(
select
	cst_id,
	count(*) over(partition by cst_id) as count_cst_id
from silver.crm_cust_info
)t
where count_cst_id = 1
)
select count(*)
from base_query

---------------------------------------------------------------------------------------

select
count(*),
count(count_cst_id)
from
(
select
	cst_id,
	count(*) as count_cst_id
from silver.crm_cust_info
group by cst_id
having count(*) = 1
--order by cst_id
)t


----------------------------------------------------------------------------------------

/* to check which customer number that has unknown birthdate data*/
select
	cid,
	bdate,
	gen
-- from bronze.erp_cust_az12
from silver.erp_cust_az12
-- where bdate > GETDATE()
where bdate is NULL

select
*
from silver.crm_cust_info
where cst_key = 'AW00029483'

select
*
from gold.dim_customers
where customer_number = 'AW00029483'

--------------------------------------------------------------------------------------------

SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id)		AS customer_key,		-- Surrogate key
	ci.cst_id								AS customer_id,
	ci.cst_key								AS customer_number,
	ci.cst_firstname						AS first_name,
	ci.cst_lastname							AS last_name,
	ci.cst_marital_status					AS marital_status,
	CASE
		 WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr					-- CRM is the master data for primary source for gender info
		 ELSE COALESCE(ca.gen,'n/a')								-- Fallback to ERP data
	END										AS gender,
	la.cntry								AS country,
	ca.bdate								AS birthdate,
	ci.cst_create_date						AS create_date
FROM silver.crm_cust_info ci 
	 LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key = ca.cid
	 LEFT JOIN silver.erp_loc_a101 la
		ON ci.cst_key = la.cid
-- where ci.cst_key = 'AW00029483'
;
