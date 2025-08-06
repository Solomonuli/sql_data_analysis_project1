/* 
================================================================================================================
PRODUCT REPORT
================================================================================================================

PURPOSE
	- 	This Report consolidates key product metrics and behaviours

Highlights:
	1. Gathers essential fields such as product names, category, subcategory and cost.
	2. Segments products by revenue into categories(High Performers, Mid Range, Low Performers)
    3. Aggregates product level metrics
		- total orders
        - total sales
        - total quantity sold
        - total customers(unique)
        - lifespan (in months)	
	4. Calculates Valuable KPIs
		- recency (months since last sale)
        - average order revenue
        - avreage monthly revenue
*/

SELECT
f.order_number,
f.customer_key,
f.order_date,
f.sales_amont,
f.quantity,
p.product_number,
p.product_name,
p.category,
p.sub_category,
p.product_cost
FROM fact_sales f
LEFT JOIN dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL;

-- Proceed to make CTE and light aggregations-product level aggregations

WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.customer_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.sub_category,
	p.product_cost
   	FROM fact_sales f
	LEFT JOIN dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
)
SELECT
product_key,
product_name,
category,
sub_category,
product_cost,
SUM(sales_amont) total_sales,
COUNT(Distinct order_number) total_orders,
SUM(quantity) total_quantity,
COUNT(DISTINCT customer_key) total_customers,
MAX(order_date) last_sale_date,
TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) product_lifespan_months
FROM base_query_CTE
GROUP BY 
product_key,
product_name,
category,
sub_category,
product_cost
;

-- proceed to make a 2nd CTE


WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.customer_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.sub_category,
	p.product_cost
   	FROM fact_sales f
	LEFT JOIN dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
)
, product_aggregations_CTE AS
(
SELECT
product_key,
product_name,
category,
sub_category,
product_cost,
SUM(sales_amont) total_sales,
COUNT(Distinct order_number) total_orders,
SUM(quantity) total_quantity,
COUNT(DISTINCT customer_key) total_customers,
MAX(order_date) last_sale_date,
TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) product_lifespan_months
FROM base_query_CTE
GROUP BY 
	product_key,
	product_name,
	category,
	sub_category,
	product_cost
)
SELECT
    product_key,
	product_name,
	category,
	sub_category,
	product_cost,
    CASE WHEN total_sales > 800000 THEN 'High Performer'
		 WHEN total_sales BETWEEN 300000 AND 800000 THEN 'Mid Range'
         ELSE 'Low Performer'
	END as product_segments,
    TIMESTAMPDIFF(month, last_sale_date, current_date()) recency,
    last_sale_date,
    -- computing Average Order Revenue = Total Sales/total Orders
    total_sales/total_orders average_order_revenue,
    -- computingAverage Monthly Revenue
    CASE WHEN product_lifespan_months THEN total_sales
         ELSE total_sales/product_lifespan_months 
	END as average_monthly_revenue
FROM product_aggregations_CTE;


-- we can proceed now to create a view.
DROP VIEW IF EXISTS product_report;
CREATE VIEW product_report AS
(
WITH base_query_CTE AS
(
	SELECT
	f.order_number,
	f.customer_key,
	f.order_date,
	f.sales_amont,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.sub_category,
	p.product_cost
   	FROM fact_sales f
	LEFT JOIN dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
)
, product_aggregations_CTE AS
(
SELECT
product_key,
product_name,
category,
sub_category,
product_cost,
SUM(sales_amont) total_sales,
COUNT(Distinct order_number) total_orders,
SUM(quantity) total_quantity,
COUNT(DISTINCT customer_key) total_customers,
MAX(order_date) last_sale_date,
TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) product_lifespan_months
FROM base_query_CTE
GROUP BY 
	product_key,
	product_name,
	category,
	sub_category,
	product_cost
)
SELECT
    product_key,
	product_name,
	category,
	sub_category,
	product_cost,
    CASE WHEN total_sales > 800000 THEN 'High Performer'
		 WHEN total_sales BETWEEN 300000 AND 800000 THEN 'Mid Range'
         ELSE 'Low Performer'
	END as product_segments,
    product_lifespan_months,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    TIMESTAMPDIFF(month, last_sale_date, current_date()) recency,
    last_sale_date,
    -- computing Average Order Revenue = Total Sales/total Orders
    total_sales/total_orders average_order_revenue,
    -- computingAverage Monthly Revenue
    CASE WHEN product_lifespan_months THEN total_sales
         ELSE total_sales/product_lifespan_months 
	END as average_monthly_revenue
FROM product_aggregations_CTE

);

SELECT * FROM product_report;
