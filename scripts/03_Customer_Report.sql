/* 
================================================================================================================
CUSTOMER REPORT
================================================================================================================

PURPOSE
	- 	This Report consolidates key customer metrics and behaviours

Highlights:
	1. Gathers essential fields such as names, ages, and transactional details.
	2. Segments customers into categories(VIP, Regular, New) and age groups
    3. Aggregates customer level metrics
		- total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)	
	4. Calculates Valuable KPIs
		- recency (months since last order)
        - average order value
        - avreage monthly spend
*/

-- 1. Gathering essential fields and developing a base query
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amont,
f.quantity,
c.customer_key,
c.customer_number,
c.first_name,
c.last_name,
c.birth_date
FROM fact_sales f
LEFT JOIN dim_customers c
ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL;


-- check for any type of aggregations needed

SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amont,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) customer_name,
TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
FROM fact_sales f
LEFT JOIN dim_customers c
ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL;

-- we then put it in a CTE to help in coming aggregations

WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)

SELECT *
FROM base_query_CTE ;

-- 2. Aggregations

WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)

SELECT 
customer_key,
customer_number,
customer_name,
customer_age,
COUNT(DISTINCT order_number) total_orders,
SUM(sales_amont) total_sales,
SUM(quantity) total_quantity,
COUNT(DISTINCT product_key) total_products,
MAX(order_date) last_order_date,
TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) customer_lifespan_months
FROM base_query_CTE 
GROUP BY
	customer_key,
	customer_number,
	customer_name,
	customer_age
;

-- we put the second query into a CTE and use that for the rest of the research or final query

WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)
, customer_aggregations_CTE AS
(
	SELECT 
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	COUNT(DISTINCT order_number) total_orders,
	SUM(sales_amont) total_sales,
	SUM(quantity) total_quantity,
	COUNT(DISTINCT product_key) total_products,
	MAX(order_date) last_order_date,
	TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) customer_lifespan_months
	FROM base_query_CTE 
	GROUP BY
		customer_key,
		customer_number,
		customer_name,
		customer_age
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	CASE WHEN customer_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN customer_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
         ELSE 'New'
	END as customer_segments,
    CASE WHEN customer_age BETWEEN 30 AND 45 THEN 'Young Adult'
		 WHEN customer_age BETWEEN 45 AND 65 THEN 'Middle Age'
         ELSE 'Senior Citizen'
	END as customer_age_groups,
    total_orders,
    total_sales,
    total_quantity,
    total_orders,
    last_order_date,
    customer_lifespan_months
FROM customer_aggregations_CTE;

-- 3. we finally proceed to calculate the KPIs

-- RECENCY - Months since last order

 WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)
, customer_aggregations_CTE AS
(
	SELECT 
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	COUNT(DISTINCT order_number) total_orders,
	SUM(sales_amont) total_sales,
	SUM(quantity) total_quantity,
	COUNT(DISTINCT product_key) total_products,
	MAX(order_date) last_order_date,
	TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) customer_lifespan_months
	FROM base_query_CTE 
	GROUP BY
		customer_key,
		customer_number,
		customer_name,
		customer_age
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	CASE WHEN customer_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN customer_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
         ELSE 'New'
	END as customer_segments,
    CASE WHEN customer_age BETWEEN 30 AND 45 THEN 'Young Adult'
		 WHEN customer_age BETWEEN 45 AND 65 THEN 'Middle Age'
         ELSE 'Senior Citizen'
	END as customer_age_groups,
    total_orders,
    total_sales,
    total_quantity,
    last_order_date,
    TIMESTAMPDIFF(month, last_order_date, current_date()) recency,
    customer_lifespan_months,
    -- computing Average Order Value = Total Sales/total Orders
    total_sales/total_orders average_order_value,
    -- computing Average Monthly Spend = Total Sales/No.Of Months
    CASE WHEN customer_lifespan_months = 0 THEN total_sales
		 ELSE total_sales/customer_lifespan_months
	END as average_monthly_spend
    FROM customer_aggregations_CTE;


-- on finishing everything, we put the whole query as a view in the database. Will act as a reference point for analysts

CREATE VIEW Customer_Report AS
(
 WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	TIMESTAMPDIFF(YEAR, c.birth_date, current_date()) customer_age
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)
, customer_aggregations_CTE AS
(
	SELECT 
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	COUNT(DISTINCT order_number) total_orders,
	SUM(sales_amont) total_sales,
	SUM(quantity) total_quantity,
	COUNT(DISTINCT product_key) total_products,
	MAX(order_date) last_order_date,
	TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) customer_lifespan_months
	FROM base_query_CTE 
	GROUP BY
		customer_key,
		customer_number,
		customer_name,
		customer_age
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	CASE WHEN customer_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN customer_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
         ELSE 'New'
	END as customer_segments,
    CASE WHEN customer_age BETWEEN 30 AND 45 THEN 'Young Adult'
		 WHEN customer_age BETWEEN 45 AND 65 THEN 'Middle Age'
         ELSE 'Senior Citizen'
	END as customer_age_groups,
    total_orders,
    total_sales,
    total_quantity,
    last_order_date,
    TIMESTAMPDIFF(month, last_order_date, current_date()) recency,
    customer_lifespan_months,
    -- computing Average Order Value = Total Sales/total Orders
    total_sales/total_orders average_order_value,
    -- computing Average Monthly Spend = Total Sales/No.Of Months
    CASE WHEN customer_lifespan_months = 0 THEN total_sales
		 ELSE total_sales/customer_lifespan_months
	END as average_monthly_spend
    FROM customer_aggregations_CTE
    );
    
    SELECT *
    FROM customer_report;
    
    
    -- examples on how to check an insight from the report
    
    SELECT 
    customer_age_groups,
    COUNT(customer_number) total_customers,
    SUM(total_sales) total_sales
    FROM customer_report
    GROUP BY customer_age_groups;
    
    SELECT 
    customer_segments,
    COUNT(customer_number) total_customers,
    SUM(total_sales) total_sales
    FROM customer_report
    GROUP BY customer_segments;
    
    
