-- ===================================================
-- 01_data_audit.sql
-- Basic dataset quality checks before analysis
-- ===================================================

-- Missing Customer IDS 
-- Rows without CustomerID cannot be used for customer analysis
SELECT 
	SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 1 ELSE 0 END) AS missing_customer 
FROM online_retail_ii; 

-- Cancelled orders by country 
-- Cancelled invoice starts with C 
SELECT Country, Count(*) as invoice_count 
FROM online_retail_ii
WHERE Invoice LIKE 'C%' 
GROUP BY Country 
ORDER BY invoice_count DESC; 

-- Cancellation rate by country
WITH sales_summary AS( 
	SELECT 
    Country,
    COUNT(CASE WHEN Invoice LIKE 'C%' THEN 1 END) AS cancelled_count, 
    COUNT(CASE WHEN Invoice NOT LIKE 'C%' AND Price > 0 THEN 1 END) as actual_sales_count
    FROM online_retail_ii 
    GROUP BY country
)
SELECT Country, 
	cancelled_count,
    actual_sales_count, 
    ROUND(cancelled_count * 100 / NULLIF(actual_sales_count,0),2) as cancellation_percentage 
FROM sales_summary 
WHERE actual_sales_count > 0
ORDER BY cancellation_percentage;


SELECT 
	COUNT(CASE WHEN Invoice NOT LIKE 'C%'  AND Price > 0 THEN 1 END) AS valid_row, 
    COUNT(*) AS total_rows,
    (COUNT(CASE WHEN Invoice NOT LIKE 'C%' AND Price > 0 THEN 1 END) * 100 / COUNT(*)) AS percentage
FROM online_retail_ii;
-- Validate sales definition. Valid row 1041652 / 1067371 : 97.5904% 

SELECT 
	MIN(Price),
    MAX(Price)
FROM online_retail_ii 
WHERE Invoice NOT LIKE 'C%' AND Price > 0;
-- Min Price: 0.03 | Max Price: 25111.09 

-- Price Investigation 
WITH Price_stats AS (
	SELECT *, 
		MIN(Price) OVER () AS min_price, 
        MAX(Price) OVER () AS max_price 
	FROM online_retail_ii 
    WHERE Invoice NOT LIKE 'C%' AND Price > 0
)
SELECT * 
FROM Price_stats
WHERE Price = min_price OR Price = max_price;

-- Top 100 Prices 
WITH ranked_price AS (
	SELECT *, 
    RANK() OVER (ORDER BY Price DESC) AS Price_rank
    FROM online_retail_ii 
    WHERE Invoice NOT LIKE 'C%' And Price > 0 
)
SELECT * 
FROM ranked_price
WHERE Price_rank < 100
ORDER BY Price_rank;
