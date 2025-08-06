-- =====================================================================================================================================================
-- Exploratory Data Analysis is used for understanding data. 
-- in this project, we are going to explore the data from database datawarehouse 2

/* 
We first start by checking what data is available. What we are working with.
This is called DATA EXPLORATION.
 */
-- ===================================================================================================================================================

SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- If you want it for a specific database, use:

SELECT * 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'data_warehouse2';

-- If you're looking for a specific table in a specific schema:

SELECT * 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'data_warehouse2'
  AND TABLE_NAME = 'crm_cust_info';

-- To get columns for a specific table in a specific database:

SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'data_warehouse2'
  AND TABLE_NAME = 'crm_cust_info';

SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'data_warehouse2'
  AND TABLE_NAME = 'dim_customers';

/*Secondly, WE divide the data into either  DIMENSIONS and MEASURES
we ask ourselves, is my column data a dimension or a measure

Dimensions - They are mostly not of numeric value 
           - They do not make sense when aggregating them e,g ID 
		   - Some examples of dimensions in our daabase include:
           Categeory column, Product Column, Birthdate Column
           
Measures - They are of numeric value
		 - They should make sense while aggregating
		- Some examples of measures in our database include:
           Sales column, Quantity Column,Age Column(gotten from calculating birthdate difference)
       
This helps in grouping data while performing analysis.

This is called DIMENSION EXPLORATION
*/
-- It involves selecting / identifying unique values in each dimenson and recognizing how the data might be grouped for later analysis. E,g

-- Explore ALL COUNTRIES our customers come from
SELECT DISTINCT Country
FROM dim_customers;    -- helps in checking how the customers are spread across the world

-- Explore All CATEGORIES "The Major Divisions"

SELECT DISTINCT category
FROM dim_products 
ORDER BY Category;

SELECT DISTINCT 
category,
sub_category
FROM dim_products 
ORDER BY Category;

SELECT DISTINCT 
category,
sub_category,
product_name
FROM dim_products 
ORDER BY Category;

/*
3rd We look at DATE EXPLORATION
*/
-- Here, we look at the date boundaries, The earliest and latest dates
-- We seek to understand the timespan and the scope of data 

-- Find the date of the first and last order
SELECT 
*
FROM fact_sales;

SELECT 
MIN(order_date) AS First_Order_Date,
MAX(order_date) AS Last_Order_Date
FROM fact_sales;

-- How many years and months of sales are available
SELECT 
MIN(order_date) AS First_Order_Date,
MAX(order_date) AS Last_Order_Date,
TIMESTAMPDIFF(Year, MIN(order_date), MAX(order_date)) AS Years_Range
FROM fact_sales;

SELECT 
MIN(order_date) AS First_Order_Date,
MAX(order_date) AS Last_Order_Date,
TIMESTAMPDIFF(Month, MIN(order_date), MAX(order_date)) AS Years_Range
FROM fact_sales;

-- Find the youngest and oldest customer
SELECT 
MIN(birth_date) AS Oldest_Customer,
timestampdiff(year, MIN(birth_date), current_date() ) Oldest_Age,
MAX(birth_date) AS Youngest_Customer,
timestampdiff(year, MAX(birth_date), current_date() ) Youngest_Age
FROM dim_customers;

-- Show customer ages
SELECT 
birth_date,
current_date() AS `current_date`,
timestampdiff(year, birth_date, current_date() ) age
FROM dim_customers
ORDER BY timestampdiff(year, birth_date, current_date() ) DESC;

/*
 4TH We look at MEASURES EXPLORATION 
*/

-- This simply means calculating and finding out the key metric of the business
-- that is the big numbers, e.g. sum of sales, total quantity, avg price etc

-- 1. Find the total sales

SELECT * FROM fact_sales;

SELECT 
SUM(sales_amont) Total_Sales
FROM fact_sales;

-- 2. Find how many items are sold
SELECT 
SUM(sales_amont) Total_Sales,
SUM(quantity) Total_Quantity
FROM fact_sales
;

-- 3. Find the average selling price
SELECT 
SUM(sales_amont) Total_Sales,
SUM(quantity) Total_Quantity,
AVG(price) Avg_Price
FROM fact_sales;

-- 4. Find the total number of orders

SELECT 
COUNT(Order_number) Total_Orders,
COUNT(DISTINCT order_number) Distinct_Orders
FROM fact_sales;             -- we use distinct so as to avoid duplicates in cases whre one orders many items in one order

SELECT 
COUNT(Distinct Order_number) Total_Orders,
SUM(sales_amont) Total_Sales,
SUM(quantity) Total_Quantity,
AVG(price) Avg_Price
FROM fact_sales;

-- 5.Find the total number of products

SELECT 
COUNT(product_key) Total_Products,
COUNT(DISTINCT product_key) Distinct_Products
FROM dim_products;  

-- 6.Find The total number of customers
SELECT 
COUNT(customer_key) Total_Customers,
COUNT(DISTINCT customer_key) Distinct_Customers
FROM dim_customers;  

-- 7.Find the total number of customers that placed an order

SELECT 
COUNT(customer_key) Total_Customers
FROM dim_customers
WHERE customer_key IN (SELECT customer_key FROM fact_sales);

-- OR

SELECT 
COUNT(DISTINCT customer_key) Total_Customers
FROM fact_sales;

-- GENERATE A REPORT THAT SHOWS ALL KEY METRICS OF THE BUSINESS

-- here, we will build 2 columns, one that shows The NAME of the Measure, another that shows the VALUE of the MEASURE


SELECT
'Total Sales' AS measure_name, 
SUM(sales_amont) AS measure_value 
FROM fact_sales
UNION ALL
SELECT
'Total Quantity' AS measure_name, 
SUM(quantity) AS measure_value 
FROM fact_sales
UNION ALL
SELECT
'Average Price' AS measure_name, 
AVG(price) AS measure_value 
FROM fact_sales
UNION ALL
SELECT
'Total Orders' AS measure_name, 
COUNT(DISTINCT order_number) AS measure_value 
FROM fact_sales
UNION ALL
SELECT
'Total Products' AS measure_name, 
COUNT(product_name) AS measure_value 
FROM dim_products
UNION ALL
SELECT
'Total Customers' AS measure_name, 
COUNT(customer_key) AS measure_value 
FROM dim_customers;

-- this measures give you a perspective of the business

/*Next we COMBINE THINGS so as to generate insight 

MAGNITUDE ANALYSIS - Comparing the measure values against the various categories and dimensions

it helps us understand the importance of different categories

Aggregate Measure By Dimension

Examples:  
Total Sales By Country
Total Quantity By Category
Average Price By Product
Total Orders By Customer

my examples
Avg Product cost by Country
Popular Product by country
Total Sales by Gender/Age

*/

-- Find Total Customers by Countries

SELECT
Country,
Count(Customer_Key) Total_Customers
FROM dim_customers
GROUP BY country
ORDER BY Total_Customers DESC;

-- Find Total Customers by Gender
SELECT
Gender,
Count(Customer_Key) Total_Customers
FROM dim_customers
GROUP BY gender
ORDER BY Total_Customers DESC;     -- helps us understand the customer demographics

-- Find the total products by category

SELECT
category,
COUNT(product_key) Total_Product
FROM dim_products
GROUP BY category
ORDER BY Total_Product DESC;

-- Find the average costs in each category

SELECT 
Category,
Avg(product_cost) Average_Cost
FROM dim_products
GROUP BY Category
Order By Average_Cost DESC;

-- Find the total revenue generated for each category

SELECT
*
FROM fact_sales AS fs
LEFT JOIN dim_products AS dp
ON fs. product_key = dp.product_key
;

SELECT
dp.category,
SUM(sales_amont) AS total_revenue
FROM fact_sales AS fs
LEFT JOIN dim_products AS dp
ON fs. product_key = dp.product_key
GROUP BY dp.category
ORDER BY total_revenue DESC;      -- Always start with the fact table

-- Find the total revenue generated by each customer

SELECT
dc.customer_key,
dc.first_name,
dc.last_name,
SUM(fs.sales_amont) AS total_revenue
FROM fact_sales AS fs
LEFT JOIN dim_customers AS dc
ON fs. customer_key = dc.customer_key
GROUP BY 
dc.customer_key,
dc.first_name, 
dc.last_name
ORDER BY total_revenue DESC;


-- FInd the distribution of sold items across all countries. (It is like finding total quantity by country)

SELECT
dc.country,
SUM(fs.quantity) AS total_products
FROM fact_sales AS fs
LEFT JOIN dim_customers AS dc
ON fs.customer_key = dc.customer_key
GROUP BY dc.country
ORDER BY total_products DESC;

-- My question. Find Avg Product cost by country.. Cant be solved because the 2 tables are not connectable
-- I assumed the products are being made  in a specific country then distributed

SELECT * FROM dim_customers;
select * from dim_products;

-- My question. Find the Popular Product by country

SELECT
dc.country,
dp.product_name,
SUM(fs.quantity) Total_Products
FROM fact_sales fs
LEFT JOIN dim_customers dc
ON fs.customer_key = dc.customer_key
LEFT JOIN dim_products dp
ON fs.product_key = dp.product_key
GROUP BY 
dc.country,
dp.product_name
ORDER BY country , total_products DESC;

-- we then proceed to rank the products per country

SELECT
dc.country,
dp.product_name,
SUM(fs.quantity) Total_Products,
RANK() OVER(Partition By Country Order By SUM(fs.quantity)) AS Product_Rank
FROM fact_sales fs
LEFT JOIN dim_customers dc
ON fs.customer_key = dc.customer_key
LEFT JOIN dim_products dp
ON fs.product_key = dp.product_key
GROUP BY 
dc.country,
dp.product_name
ORDER BY country , total_products DESC;

-- we can create a CTE or even a subquery, but CTE is much clearer to use, so as to focus on a smaller dataset, say top 5


WITH RankedProducts_CTE AS (
  SELECT
    dc.country,
    dp.product_name,
    SUM(fs.quantity) AS Total_Products,
    RANK() OVER(PARTITION BY dc.country ORDER BY SUM(fs.quantity) DESC) AS Product_Rank
  FROM fact_sales fs
  LEFT JOIN dim_customers dc ON fs.customer_key = dc.customer_key
  LEFT JOIN dim_products dp ON fs.product_key = dp.product_key
  GROUP BY 
    dc.country,
    dp.product_name
)

SELECT *
FROM RankedProducts_CTE
WHERE Product_Rank <= 5 AND country != 'n/a'
ORDER BY country, Product_Rank;

-- seems like the water bottle 30 oz is the most popular product in all countries

-- my question -- Find Total Sales by Gender
SELECT
dc.Gender,
SUM(fs.sales_amont) Total_Sales
FROM fact_sales fs
LEFT JOIN dim_customers dc
ON fs.customer_key = dc.customer_key
GROUP BY gender
ORDER BY Total_Sales DESC; 

/* Next WE perform RANKING ANALYSIS

This means to order the values of dimensions by measure in order to identify TOP N PERFORMERS and BOTTOM N PERFORMERS

*/

-- Find the 5 products that generate the HIGHEST revenue

SELECT
dp.product_name,
SUM(fs.sales_amont) Total_Revenue,
RANK() OVER(Order By SUM(fs.sales_amont) DESC) Product_Rank
FROM fact_sales fs
LEFT JOIN dim_products dp
ON fs.product_key = dp.product_key
GROUP BY dp.product_name
ORDER BY Total_Revenue DESC
 ;

SELECT *
FROM (
		SELECT
		dp.product_name,
		SUM(fs.sales_amont) Total_Revenue,
		RANK() OVER(Order By SUM(fs.sales_amont) DESC) Product_Rank
		FROM fact_sales fs
		LEFT JOIN dim_products dp
		ON fs.product_key = dp.product_key
		GROUP BY dp.product_name
		ORDER BY Total_Revenue DESC
) T
WHERE Product_Rank <= 5;


-- Find the 5 products that generate the LOWEST revenue
SELECT
dp.product_name,
SUM(fs.sales_amont) Total_Revenue,
RANK() OVER(Order By SUM(fs.sales_amont) ASC) Product_Rank
FROM fact_sales fs
LEFT JOIN dim_products dp
ON fs.product_key = dp.product_key
GROUP BY dp.product_name
ORDER BY Total_Revenue ASC
 ;

SELECT *
FROM (
		SELECT
		dp.product_name,
		SUM(fs.sales_amont) Total_Revenue,
		RANK() OVER(Order By SUM(fs.sales_amont) ASC) Product_Rank
		FROM fact_sales fs
		LEFT JOIN dim_products dp
		ON fs.product_key = dp.product_key
		GROUP BY dp.product_name
		ORDER BY Total_Revenue 
) T
WHERE Product_Rank <= 5;

-- you can change the dimensions as well so as to get different data

SELECT
dp.sub_category,
SUM(fs.sales_amont) Total_Revenue,
RANK() OVER(Order By SUM(fs.sales_amont) DESC) Product_Rank
FROM fact_sales fs
LEFT JOIN dim_products dp
ON fs.product_key = dp.product_key
GROUP BY dp.sub_category
ORDER BY Total_Revenue DESC
 ;


-- Find top 10 customers with highest revenue

SELECT 
dc.customer_key,
dc.first_name,
dc.last_name,
SUM(fs.sales_amont) Total_Revenue,
RANK() OVER(Order By SUM(fs.sales_amont) DESC) Revenue_Rank
FROM fact_sales fs
LEFT JOIN dim_customers dc
ON fs.customer_key = dc.customer_key
GROUP BY
dc.customer_key,
dc.first_name,
dc.last_name
ORDER BY Total_Revenue DESC
LIMIT 10;

-- OR    

SELECT * 
FROM (
	SELECT 
		dc.customer_key,
		dc.first_name,
		dc.last_name,
		SUM(fs.sales_amont) Total_Revenue,
		RANK() OVER(Order By SUM(fs.sales_amont) DESC) Revenue_Rank
	FROM fact_sales fs
		LEFT JOIN dim_customers dc
		ON fs.customer_key = dc.customer_key
		GROUP BY
		dc.customer_key,
		dc.first_name,
		dc.last_name
		ORDER BY Total_Revenue DESC
) T
WHERE Revenue_Rank <= 10;


-- Find 3 customers with fewest orders placed

SELECT 
dc.customer_key,
dc.first_name,
dc.last_name,
COUNT(DISTINCT order_number) Orders_Placed
FROM fact_sales fs
LEFT JOIN dim_customers dc
ON fs.customer_key = dc.customer_key
GROUP BY
dc.customer_key,
dc.first_name,
dc.last_name
ORDER BY Orders_Placed ASC
LIMIT 3;

-- Note that in the above query, the LIMIT clause helps in filtering the data
