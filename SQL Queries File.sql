-- 1. Provide a breakdown of the regions where our company operates, along with a list of the specific market countries in each region

SELECT DISTINCT market,region FROM dim_customer
ORDER BY region ;

-- 2. Provide a detailed overview of our current product line available to our customers

SELECT division,segment,category from dim_product
GROUP BY division,segment,category;

-- 3. Provide the various sales channels we use to distribute our products in the international market

SELECT DISTINCT `channel` FROM dim_customer;

-- 4(a). Provide a breakdown of the gross sales generated from each sales channel for fiscal year 2020?

WITH channel_sales AS (
    SELECT
        d.channel,
        SUM(f.sold_quantity * g.gross_price) AS gross_sales_mln
    FROM fact_sales_monthly f
    JOIN fact_gross_price g ON f.product_code = g.product_code AND f.fiscal_year = g.fiscal_year
    JOIN dim_customer d ON f.customer_code = d.customer_code
    WHERE f.fiscal_year = 2020	
    GROUP BY d.channel
),
total_sales AS (
    SELECT SUM(gross_sales_mln) AS total_sales
    FROM channel_sales
)
SELECT
    cs.channel,
    CONCAT(ROUND(cs.gross_sales_mln/1000000,2),"M") AS gross_sales_mln,
    ROUND((cs.gross_sales_mln / ts.total_sales) * 100,2) AS percentage
FROM channel_sales cs, total_sales ts;

-- 4(b). Provide a breakdown of the gross sales generated from each sales channel for fiscal year 2021?

WITH channel_sales AS (
    SELECT
        d.channel,
        SUM(f.sold_quantity * g.gross_price) AS gross_sales_mln
    FROM fact_sales_monthly f
    JOIN fact_gross_price g ON f.product_code = g.product_code AND f.fiscal_year = g.fiscal_year
    JOIN dim_customer d ON f.customer_code = d.customer_code
    WHERE f.fiscal_year = 2021
    GROUP BY d.channel
),
total_sales AS (
    SELECT SUM(gross_sales_mln) AS total_sales
    FROM channel_sales
)
SELECT
    cs.channel,
    CONCAT(ROUND(cs.gross_sales_mln/1000000,2),"M") AS gross_sales_mln,
    ROUND((cs.gross_sales_mln / ts.total_sales) * 100,2) AS percentage
FROM channel_sales cs, total_sales ts;

-- 5(a). Analyze and summarize the direct sales performance of the Atliq Exclusive regions for fiscal years 2020 and 2021?

WITH regional_sales AS (
    SELECT 
        d.region,
        f.fiscal_year,
        SUM(f.sold_quantity * g.gross_price) AS total_sales_amount
    FROM fact_sales_monthly f
    JOIN fact_gross_price g
        ON f.product_code = g.product_code
        AND f.fiscal_year = g.fiscal_year
    JOIN dim_customer d
        ON f.customer_code = d.customer_code
	WHERE d.customer = 'Atliq Exclusive' and d.channel = 'direct'
    GROUP BY d.region, f.fiscal_year
)
SELECT 
    region,
    SUM(CASE WHEN fiscal_year = 2020 THEN total_sales_amount ELSE 0 END) AS sales_2020,
    SUM(CASE WHEN fiscal_year = 2021 THEN total_sales_amount ELSE 0 END) AS sales_2021
FROM regional_sales
GROUP BY region;

-- 5(b). Analyze and summarize the direct sales performance of the Atliq e-Store regions for fiscal years 2020 and 2021?

WITH regional_sales AS (
    SELECT 
        d.region,
        f.fiscal_year,
        SUM(f.sold_quantity * g.gross_price) AS total_sales_amount
    FROM fact_sales_monthly f
    JOIN fact_gross_price g
        ON f.product_code = g.product_code
        AND f.fiscal_year = g.fiscal_year
    JOIN dim_customer d
        ON f.customer_code = d.customer_code
	WHERE d.customer = 'Atliq e store' and d.channel = 'direct'
    GROUP BY d.region, f.fiscal_year
)
SELECT 
    region,
    SUM(CASE WHEN fiscal_year = 2020 THEN total_sales_amount ELSE 0 END) AS sales_2020,
    SUM(CASE WHEN fiscal_year = 2021 THEN total_sales_amount ELSE 0 END) AS sales_2021
FROM regional_sales
GROUP BY region;

-- 6. Provide a detailed count of the number of products we offer to customers within each product segment

SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM dim_product 
GROUP BY segment
ORDER BY product_count DESC;

-- 7(a). Calculate the growth percentage of our product offerings from FY 2020 to FY 2021?

WITH product_counts AS (
    SELECT fiscal_year,	
						count(distinct product_code) as unique_products
		FROM fact_sales_monthly
        group by fiscal_year
)
SELECT 
	pc_2020.unique_products AS unique_products_2020,
	pc_2021.unique_products AS unique_products_2021,
    (pc_2021.unique_products - pc_2020.unique_products) * 100.0 / pc_2020.unique_products AS percentage_chg
FROM product_counts pc_2020
JOIN product_counts pc_2021
ON pc_2020.fiscal_year = 2020 and pc_2021.fiscal_year = 2021;


-- 7(b). Analyze and identify which product segment experienced the most significant increase in offerings from FY 2020 to FY 2021?

WITH product_counts AS (
    SELECT
        d.segment,
        fiscal_year,
        COUNT(distinct d.product_code) AS product_count
    FROM dim_product d
    JOIN fact_sales_monthly f ON d.product_code = f.product_code
    GROUP BY d.segment, fiscal_year
)

SELECT
        pc_2020.segment AS segment,
        pc_2020.product_count AS product_count_2020,
        pc_2021.product_count AS product_count_2021,
        pc_2021.product_count - pc_2020.product_count AS difference
    FROM product_counts pc_2020
    JOIN product_counts pc_2021 ON pc_2020.segment = pc_2021.segment AND pc_2020.fiscal_year = 2020 AND pc_2021.fiscal_year = 2021
    ORDER BY difference DESC;
    
-- 8. Evaluate whether the increase in the number of products offered in the market contributed to higher sales for those product segments in FY 2021 compared to 2020

WITH sales_sum AS (
    SELECT
        d.segment,
        f.fiscal_year,
        sum(gross_price * sold_quantity) AS total_sales
    FROM dim_product d
    JOIN fact_sales_monthly f ON d.product_code = f.product_code
    JOIN fact_gross_price g ON f.product_code = g.product_code and f.fiscal_year = g.fiscal_year
    GROUP BY d.segment, fiscal_year
)

SELECT
        ss_2020.segment AS segment,
        CONCAT(ROUND(ss_2020.total_sales/1000000,2),"M") AS total_sales_2020,
        CONCAT(ROUND(ss_2021.total_sales/1000000,2),"M") AS total_sales_2021,
        CONCAT(ROUND((ss_2021.total_sales - ss_2020.total_sales)/1000000,2),"M") AS difference
    FROM sales_sum ss_2020
    JOIN sales_sum ss_2021 ON ss_2020.segment = ss_2021.segment AND ss_2020.fiscal_year = 2020 AND ss_2021.fiscal_year = 2021
    ORDER BY (ss_2021.total_sales - ss_2020.total_sales) DESC;
    
-- 9. Provide the products with the highest and lowest manufacturing costs?

(SELECT 
		f.product_code,
		product,
        manufacturing_cost 
	FROM fact_manufacturing_cost f
	JOIN dim_product d
	ON d.product_code = f.product_code
	ORDER BY manufacturing_cost DESC
	LIMIT 1)
	UNION
(SELECT 
		f.product_code,
        product,
        manufacturing_cost 
	FROM fact_manufacturing_cost f
	JOIN dim_product d
	ON d.product_code = f.product_code
	ORDER BY manufacturing_cost ASC
	LIMIT 1);
    
-- 10. Provide the top three products in each division based on total sold quantity for fiscal year 2021

WITH ranked_products AS (
    SELECT
        d.division,
        f.product_code,
        d.product,
        d.category,
        d.variant,
        SUM(f.sold_quantity) AS total_sold_quantity,
        ROW_NUMBER() OVER (PARTITION BY d.division ORDER BY SUM(f.sold_quantity) DESC) AS rank_order
    FROM fact_sales_monthly f
    JOIN dim_product d ON f.product_code = d.product_code
    WHERE f.fiscal_year = 2021
    GROUP BY d.division, f.product_code, d.product,d.variant,d.category
)
SELECT
    division,
    product_code,
    product,
    category,
    variant,
    total_sold_quantity,
    rank_order
FROM ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;

-- 11(a). Identify the customers in the Indian market who received the average high pre-invoice discount percentage for fiscal year 2021

SELECT 
		f.customer_code,
        d.customer,
        pre_invoice_discount_pct 
	FROM fact_pre_invoice_deductions f
	JOIN dim_customer d
	ON f.customer_code = d.customer_code
	WHERE pre_invoice_discount_pct > 
									(SELECT AVG(pre_invoice_discount_pct) 
                                    FROM fact_pre_invoice_deductions 
                                    WHERE fiscal_year = 2021) 
	AND fiscal_year = 2021 AND market = 'India'
	ORDER BY 3 DESC;

-- 11(b). Compile a list of the top 10 customers by total sales in the Indian market for fiscal year 2021

SELECT
    d.customer_code,
    d.customer,
    SUM(f.sold_quantity * g.gross_price) AS total_sales
FROM fact_sales_monthly f
JOIN fact_gross_price g ON f.product_code = g.product_code AND f.fiscal_year = g.fiscal_year
JOIN dim_customer d ON f.customer_code = d.customer_code
WHERE f.fiscal_year = 2021 AND market = 'INDIA'
GROUP BY d.customer_code, d.customer
ORDER BY total_sales DESC
LIMIT 10;

-- 12. Analyze and determine which quarter of FY 2020 had the highest total sold quantity

WITH fiscal_quarters AS (
    SELECT
        CASE
            WHEN f.date BETWEEN '2019-09-01' AND '2019-11-30' THEN 'Q1'
            WHEN f.date BETWEEN '2019-12-01' AND '2020-02-29' THEN 'Q2'
            WHEN f.date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'Q3'
            WHEN f.date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'Q4'
        END AS Quarter,
        SUM(f.sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly f
    WHERE f.fiscal_year = 2020
    GROUP BY Quarter
)
SELECT
    Quarter,
    total_sold_quantity
FROM fiscal_quarters
ORDER BY total_sold_quantity DESC;

-- 13. Prepare a comprehensive report detailing the gross sales amount for the customer 'Atliq Exclusive' on a monthly basis

SELECT 
			MONTH(`date`) AS `Month`,
			f_sales.fiscal_year,
			SUM(gross_price*sold_quantity) AS gross_sales_amount 
		FROM fact_sales_monthly f_sales
		JOIN fact_gross_price f_price 
		ON f_sales.product_code = f_price.product_code AND f_sales.fiscal_year = f_price.fiscal_year
		JOIN dim_customer d_cust 
		ON f_sales.customer_code = d_cust.customer_code
		WHERE customer = 'Atliq Exclusive'
		GROUP BY MONTH(`date`),fiscal_year
		ORDER BY 2;