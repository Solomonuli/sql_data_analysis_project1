-- ================================================================================================================================================

-- This stage is meant to analyse the data deeply ,exploring various insights which will be used to generate stakeholder reports

-- =================================================================================================================================================

/*
-- CHANGE OVER TIME ANALYSIS --
 This analyses how a measure evolves over time
 Helps track trends and identify seasonality in your data
 
 We are going to aggregate a measure based on Date Dimension  e.g
Total Sales By Year,
Average Cost By Month
*/

-- 1. Analyze Sales Perfomance Over Time(Month/Year)

SELECT *
FROM fact_sales;

SELECT
order_date,
sales_amont
FROM fact_sales;

SELECT
order_date,
SUM(sales_amont) Total_Sales
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_date
ORDER BY order_date;

-- we dont aggregate data on a day level, we use bigger dimensions such as years or months

SELECT
YEAR(order_date) Order_Years,
SUM(sales_amont) Total_Sales
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- we can add more measures to our query,such as number of customers over time

SELECT
YEAR(order_date) Order_Years,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

SELECT
YEAR(order_date) Order_Years,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers,
SUM(quantity) Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- this information gives a high level overview of insights that help in decision making
-- lets agggregate now by the months - it combines all months across all years

SELECT
Month(order_date) Order_Month,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers,
SUM(quantity) Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY Month(order_date)
ORDER BY Month(order_date);

-- this shows the changes in of sales in different seasons , hence giving an insight of seasonal changes in your company
-- we can further go down and specify both the year and month

SELECT
YEAR(order_date) Order_Year,
Month(order_date) Order_Month,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers,
SUM(quantity) Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), Month(order_date)
ORDER BY YEAR(order_date), Month(order_date);

-- we can as well just combine the 2 columns into 1

SELECT
DATE(order_date) Order_Date,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers,
SUM(quantity) Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE(order_date)
ORDER BY DATE(order_date);  -- using this way removes the grouping aspect in MySQL

SELECT
DATE_FORMAT(order_date, '%Y-%m-01') Order_Date,
SUM(sales_amont) Total_Sales,
COUNT(DISTINCT customer_key) Total_Customers,
SUM(quantity) Total_Quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY DATE_FORMAT(order_date, '%Y-%m-01'); -- using this way retains the grouping aspect in MySQL, focusing on the month only

/*
-- CUMULATIVE ANALYSIS --
This aggregates the data progressively ovr time
It analyses how the business is growing/declining(progressing) over time

We are going to aggregate a cumulative measure based on Date Dimension e.g

Running Total Sales By Year,
Moving Average of Sales By Month
*/

-- 2. Calculate the Total Sales Per Month , Running Total Of Sales Over Time and Moving Average of Price

SELECT
DATE_FORMAT(order_date, '%Y-%m-01') Order_Month,
SUM(sales_amont) Total_Sales
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01');     -- never forget to get rid of the nulls

-- we then proceed to calculate the running total by using the above query as a subquery and a window function
SELECT
Order_Month,
Total_Sales,
SUM(Total_Sales) OVER(Order By Order_Month) Running_Total_Sales
FROM (
	SELECT
	DATE_FORMAT(order_date, '%Y-%m-01') Order_Month,
	SUM(sales_amont) Total_Sales
	FROM fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) t
;
-- we can also just limit the running total to a yearly result by partitioning

SELECT
Order_Year,
Total_Sales,
SUM(Total_Sales) OVER(Order By Order_Year) Running_Total_Sales
FROM (
	SELECT
	DATE_FORMAT(order_date, '%Y-01-01') Order_Year,  -- Note the changes
	SUM(sales_amont) Total_Sales
	FROM fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATE_FORMAT(order_date, '%Y-01-01')
) t
;

-- lets now add the moving average of the price per month then per year

SELECT
Order_Month,
Total_Sales,
SUM(Total_Sales) OVER(Order By Order_Month) Running_Total_Sales,
ROUND(AVG(Avg_Price) OVER(Order By Order_Month),2) Moving_Average_Price
FROM (
	SELECT
	DATE_FORMAT(order_date, '%Y-%m-01') Order_Month,
	SUM(sales_amont) Total_Sales,
    AVG(price) Avg_Price
	FROM fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) t
;

SELECT
date_format(order_date, '%Y-%m-01'),
AVG(price)
FROM fact_sales
Group By  
date_format(order_date, '%Y-%m-01');  -- this is to check whether the avg price is correct

-- year moving avg
SELECT
Order_Year,
Total_Sales,
SUM(Total_Sales) OVER(Order By Order_Year) Running_Total_Sales,
ROUND(AVG(Avg_Price) OVER(Order By Order_Year),2) Moving_Average_Price
FROM (
	SELECT
	DATE_FORMAT(order_date, '%Y-01-01') Order_Year,
	SUM(sales_amont) Total_Sales,
    AVG(price) Avg_Price
	FROM fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATE_FORMAT(order_date, '%Y-01-01')
) t
;

/*
-- PERFORMANCE ANALYSIS --
This is the process of comparing the current value to a target value

its done by subtracting the target measure from the current measure e.g

Current Sales - Average Sales
Current Year Sales - Previous Year Sales
Current Sales - Lowest Sales

For this analysis we normally use aggregate window functions and value window functions
*/

-- 3. Analyze the yearly performance of products by comparing each products sales to both its avg sales performance and previous year performance

SELECT
fs.order_date,
dp.product_name,
fs.sales_amont
FROM fact_sales as fs
LEFT JOIN dim_products as dp
on fs.product_key = dp.product_key
WHERE fs.order_date IS NOT NULL
;

SELECT
YEAR(fs.order_date) Order_Year,
dp.product_name,
SUM(fs.sales_amont) Current_Sales
FROM fact_sales as fs
LEFT JOIN dim_products as dp
on fs.product_key = dp.product_key
WHERE fs.order_date IS NOT NULL
GROUP BY 
YEAR(fs.order_date),
dp.product_name
;

-- we then create a CTE

WITH yearly_product_sales_CTE AS
	(SELECT
	YEAR(fs.order_date) Order_Year,
	dp.product_name,
	SUM(fs.sales_amont) Current_Sales
	FROM fact_sales as fs
	LEFT JOIN dim_products as dp
	on fs.product_key = dp.product_key
	WHERE fs.order_date IS NOT NULL
	GROUP BY 
	YEAR(fs.order_date),
	dp.product_name
)
SELECT 
Order_Year,
product_name,
Current_Sales
FROM  yearly_product_sales_CTE
ORDER BY product_name , Order_Year;

-- we next do the average

WITH yearly_product_sales_CTE AS
	(SELECT
	YEAR(fs.order_date) Order_Year,
	dp.product_name,
	SUM(fs.sales_amont) Current_Sales
	FROM fact_sales as fs
	LEFT JOIN dim_products as dp
	on fs.product_key = dp.product_key
	WHERE fs.order_date IS NOT NULL
	GROUP BY 
	YEAR(fs.order_date),
	dp.product_name
)
SELECT 
Order_Year,
product_name,
Current_Sales,
AVG(Current_Sales) OVER(Partition By product_name) Average_Sales,
Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) AS Avg_Diff
FROM  yearly_product_sales_CTE
ORDER BY product_name , Order_Year;

-- its always good to have some sort of indicator on the info 

WITH yearly_product_sales_CTE AS
	(SELECT
	YEAR(fs.order_date) Order_Year,
	dp.product_name,
	SUM(fs.sales_amont) Current_Sales
	FROM fact_sales as fs
	LEFT JOIN dim_products as dp
	on fs.product_key = dp.product_key
	WHERE fs.order_date IS NOT NULL
	GROUP BY 
	YEAR(fs.order_date),
	dp.product_name
)
SELECT 
Order_Year,
product_name,
Current_Sales,
AVG(Current_Sales) OVER(Partition By product_name) Average_Sales,
Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) AS Avg_Diff,
CASE WHEN Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) > 0 THEN 'Above Average'
	 WHEN Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) < 0 THEN 'Below Average'
     ELSE 'Average'
END AS Avg_Change
FROM  yearly_product_sales_CTE
ORDER BY product_name , Order_Year;

-- next , we compare the sales of thecurrent year to the previous year

WITH yearly_product_sales_CTE AS
	(SELECT
	YEAR(fs.order_date) Order_Year,
	dp.product_name,
	SUM(fs.sales_amont) Current_Sales
	FROM fact_sales as fs
	LEFT JOIN dim_products as dp
	on fs.product_key = dp.product_key
	WHERE fs.order_date IS NOT NULL
	GROUP BY 
	YEAR(fs.order_date),
	dp.product_name
)
SELECT 
Order_Year,
product_name,
Current_Sales,
AVG(Current_Sales) OVER(Partition By product_name) Average_Sales,
Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) AS Avg_Diff,
CASE WHEN Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) > 0 THEN 'Above Average'
	 WHEN Current_Sales - AVG(Current_Sales) OVER(Partition By product_name) < 0 THEN 'Below Average'
     ELSE 'Average'
END AS Avg_Change,
LAG(current_sales) OVER(Partition By product_name ORDER BY order_year) Prev_Yr_Sales,
Current_Sales - LAG(current_sales) OVER(Partition By product_name ORDER BY order_year) Prev_Yr_Diff,
CASE WHEN Current_Sales - LAG(current_sales) OVER(Partition By product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN Current_Sales - LAG(current_sales) OVER(Partition By product_name ORDER BY order_year) < 0 THEN 'Decrease'
     ELSE 'No Change'
END AS Year_Change
FROM  yearly_product_sales_CTE
ORDER BY product_name , Order_Year;

/* 
Part to Whole Analysis
- We use this to compare the proportion of a part to a whole. That is, how an individual part is performing to the overall
allowing us to understand which category has the greatest impact on the business.

e.g Sales / Total Sales * 100 By Category
Quantity / Total Quantity * 100 By Country
*/

-- 4. Which categories contribute the most to the overall sales

SELECT
dp.category,
fs.sales_amont
FROM fact_sales as fs
LEFT JOIN dim_products as dp
on fs.product_key = dp.product_key;

SELECT
dp.category,
sum(fs.sales_amont) Total_Sales
FROM fact_sales as fs
LEFT JOIN dim_products as dp
on fs.product_key = dp.product_key
GROUP BY Category;


WITH Category_sales_CTE AS
(
	SELECT
	dp.category,
	sum(fs.sales_amont) Total_Sales
	FROM fact_sales as fs
	LEFT JOIN dim_products as dp
	on fs.product_key = dp.product_key
	GROUP BY Category
)
SELECT
Category,
Total_Sales,
SUM(Total_Sales) OVER() Overall_Sales,
CONCAT(ROUND(Total_Sales/ SUM(Total_Sales) OVER() * 100, 2), '%' ) AS Percentage_Total
FROM Category_sales_CTE;

-- This can be used for many other measures to help executives make decisions faster

/* 
DATA SEGEMENTATION
- This means grouping up the data based on a specific range. It helps understand the correlation between 2 measures

e.g Total products By Sales Range
    Total Customers By Age Group
    
    */
    
-- 5. Segment products into cost ranges and count how many products fall into each segment

SELECT 
product_key,
product_cost
FROM dim_products;

SELECT 
product_key,
product_cost,
CASE WHEN product_cost <= 500 THEN 'Low Cost'
	 WHEN product_cost BETWEEN 500  AND  1500 THEN 'Average Cost'
     ELSE 'High Cost'
END as Cost_Range
FROM dim_products
Order By product_cost
;

SELECT 
Cost_Range,
Count(Product_key) Total_Products
FROM (
	SELECT 
	product_key,
	product_cost,
	CASE WHEN product_cost <= 500 THEN 'Low Cost'
		 WHEN product_cost BETWEEN 500 AND 1500 THEN 'Average Cost'
		 ELSE 'High Cost'
	END as Cost_Range
	FROM dim_products
	Order By product_cost
)t
GROUP BY Cost_Range
Order By Total_Products DESC;

/*
-- TASK --

Group Customers into 3 segments based on their spending behaviour:
-VIP ; at least 12 months of history and spending more than 5,000
-Regular; at least 12 months of history but spending 5000 or less
-New ; lifespan less than 12 months

And find total number of customers by each group.
*/

SELECT 
c.customer_key,
f.order_date,
f.sales_amont
FROM fact_sales f
LEFT JOIN dim_customers c
ON f.customer_key = c.customer_key;

-- we first calculate the lifespan

SELECT 
c.customer_key,
SUM(f.sales_amont) Total_Spend,
MIN(Order_date) first_order,
MAX(Order_date) last_order,
TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) AS Lifespan
FROM fact_sales f
LEFT JOIN dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key;

-- we create a cte

WITH CTE_Customer_History AS
(
	SELECT 
	c.customer_key,
	SUM(f.sales_amont) Total_Spend,
	MIN(Order_date) first_order,
	MAX(Order_date) last_order,
	TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) AS Lifespan
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)
SELECT
customer_key,
Total_Spend,
CASE WHEN Lifespan >= 12  AND Total_Spend > 5000 THEN 'VIP'
	 WHEN Lifespan >= 12  AND Total_Spend <= 5000 THEN 'Regular'
     ELSE 'New'
END as Customer_Segments
FROM CTE_Customer_History;

-- we can  then cte the main query to solve our third problem

WITH CTE_Customer_History AS
(
	SELECT 
	c.customer_key,
	SUM(f.sales_amont) Total_Spend,
	MIN(Order_date) first_order,
	MAX(Order_date) last_order,
	TIMESTAMPDIFF(month, MIN(Order_date), MAX(Order_date)) AS Lifespan
	FROM fact_sales f
	LEFT JOIN dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)
,CTE_Customer_Segments AS
	(
    SELECT
	customer_key,
	Total_Spend,
	CASE WHEN Lifespan >= 12  AND Total_Spend > 5000 THEN 'VIP'
		 WHEN Lifespan >= 12  AND Total_Spend <= 5000 THEN 'Regular'
		 ELSE 'New'
	END as Customer_Segments
	FROM CTE_Customer_History
)
SELECT
customer_segments,
COUNT(Customer_key) Total_Customers
FROM CTE_Customer_Segments
GROUP BY customer_segments
ORDER BY Total_Customers DESC;
