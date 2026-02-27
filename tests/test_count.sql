/*
Below are test to check the count number of cst_id in
	bronze.crm_cust_info : 18493
	silver.crm_cust_info : 18484
*/

select 
*
from gold.dim_customers

---------------------------------------------------------------------------------------

select 
*
from gold.fact_sales

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
