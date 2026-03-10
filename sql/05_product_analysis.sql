-- ===================================================
-- 05_product_analysis.sql
-- Product performance analysis
--
-- Focus Area:
-- 1. Top products by revenue
-- 2. Top products by units sold
-- 3. Product return rate
-- ===================================================

-- 1. Top products by revenue, excluding non-product stock code. 
SELECT 
    StockCode,
    Description,
    ROUND(SUM(Price * Quantity), 2) AS revenue
FROM online_retail_ii 
WHERE Quantity > 0 
  AND Price > 0 
  AND StockCode NOT IN ('M', 'POST', 'DOT', 'ADJUST', 'D')
  AND StockCode NOT LIKE 'AMAZONFEE%'
  AND StockCode NOT LIKE 'BANK CHARGES%'
GROUP BY StockCode, Description
ORDER BY revenue DESC
LIMIT 20;

-- 2. Top products by units sold, Rank products by total quantity. 
SELECT 
    StockCode,
    Description,
    SUM(Quantity) AS units_sold
FROM online_retail_ii
WHERE Quantity > 0
  AND Price > 0
  AND StockCode NOT IN ('M', 'POST', 'DOT', 'ADJUST', 'D')
  AND StockCode NOT LIKE 'AMAZONFEE%'
  AND StockCode NOT LIKE 'BANK CHARGES%'
GROUP BY StockCode, Description
ORDER BY units_sold DESC
LIMIT 20;

-- 3. Product return rate, total sold units VS returned units. Minimum sale threshold is used to reduce distortion from low volume products.
WITH return_cte AS (
    SELECT 
        StockCode,
        Description,
        SUM(ABS(Quantity)) AS return_units,
        ROUND(SUM(ABS(Quantity * Price)), 2) AS return_revenue
    FROM online_retail_ii
    WHERE Quantity < 0
      AND StockCode NOT LIKE 'S%' 
      AND StockCode NOT IN ('M', 'POST', 'DOT', 'ADJUST', 'D')
      AND StockCode NOT LIKE 'AMAZONFEE%'
      AND StockCode NOT LIKE 'BANK CHARGES%'
    GROUP BY StockCode, Description
),
sale_table AS (
    SELECT 
        StockCode,
        Description,
        SUM(Quantity) AS sale_units,
        ROUND(SUM(Quantity * Price), 2) AS sale_revenue
    FROM online_retail_ii
    WHERE Quantity > 0
      AND Price > 0
      AND StockCode NOT LIKE 'S%' 
      AND StockCode NOT IN ('M', 'POST', 'DOT', 'ADJUST', 'D')
      AND StockCode NOT LIKE 'AMAZONFEE%'
      AND StockCode NOT LIKE 'BANK CHARGES%'
    GROUP BY StockCode, Description
)
SELECT 
    s.StockCode,
    s.Description,
    s.sale_units,
    s.sale_revenue,
    COALESCE(r.return_units, 0) AS return_units,
    COALESCE(r.return_revenue, 0) AS return_revenue,
    ROUND(
        COALESCE(r.return_units, 0) / NULLIF(s.sale_units, 0) * 100,
        2
    ) AS return_rate_percentage
FROM sale_table s
LEFT JOIN return_cte r
    ON s.StockCode = r.StockCode
   AND s.Description = r.Description
WHERE s.sale_units >= 50
ORDER BY return_rate_percentage DESC;
