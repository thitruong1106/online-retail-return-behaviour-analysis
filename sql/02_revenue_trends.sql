-- ===================================================
-- 02_revenue_trends.sql
-- Revenue trend analysis
-- Includes:
-- 1. Monthly gross revenue
-- 2. Monthly performance with returns (gross revenue, return value, net revenue, return rate)
-- 3. Quarterly revenue summary
-- 4. Month-over-month revenue growth
-- ===================================================

-- 1.Monthly gross revenue
SELECT 
    YEAR(InvoiceDate) AS year,
    MONTH(InvoiceDate) AS month,
    ROUND(SUM(Quantity * Price), 2) AS gross_revenue
FROM online_retail_ii
WHERE Quantity > 0
  AND Price > 0
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY year, month;

-- 2.Monthly gross revenue, return value, net revenue, and return rate
WITH gross AS (
    SELECT 
        YEAR(InvoiceDate) AS year,
        MONTH(InvoiceDate) AS month,
        SUM(Quantity * Price) AS gross_revenue
    FROM online_retail_ii
    WHERE Quantity > 0
      AND Price > 0
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
),
returns AS (
    SELECT 
        YEAR(InvoiceDate) AS year,
        MONTH(InvoiceDate) AS month,
        SUM(ABS(Quantity * Price)) AS return_value
    FROM online_retail_ii
    WHERE Quantity < 0
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
    g.year,
    g.month,
    ROUND(g.gross_revenue, 2) AS gross_revenue,
    ROUND(COALESCE(r.return_value, 0), 2) AS return_value,
    ROUND(g.gross_revenue - COALESCE(r.return_value, 0), 2) AS net_revenue,
    ROUND(COALESCE(r.return_value, 0) / g.gross_revenue * 100, 2) AS return_rate_percent
FROM gross g
LEFT JOIN returns r
    ON g.year = r.year
   AND g.month = r.month
ORDER BY g.year, g.month;

-- 3. Quarterly revenue summary
WITH valid_sales AS (
    SELECT
        YEAR(InvoiceDate) AS year,
        MONTH(InvoiceDate) AS month,
        Quantity * Price AS revenue,
        CASE
            WHEN MONTH(InvoiceDate) IN (1,2,3) THEN 'Q1'
            WHEN MONTH(InvoiceDate) IN (4,5,6) THEN 'Q2'
            WHEN MONTH(InvoiceDate) IN (7,8,9) THEN 'Q3'
            WHEN MONTH(InvoiceDate) IN (10,11,12) THEN 'Q4'
        END AS quarter
    FROM online_retail_ii
    WHERE Quantity > 0
      AND Price > 0
)
SELECT
    year,
    quarter,
    ROUND(SUM(revenue), 2) AS quarterly_revenue
FROM valid_sales
GROUP BY year, quarter
ORDER BY year, quarter;

-- 4. Month to month revenue growth 
WITH monthly_revenue AS (
    SELECT
        YEAR(InvoiceDate) AS year,
        MONTH(InvoiceDate) AS month,
        ROUND(SUM(Quantity * Price), 2) AS revenue
    FROM online_retail_ii
    WHERE Quantity > 0
      AND Price > 0
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
),
revenue_with_lag AS (
    SELECT
        year,
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY year, month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    year,
    month,
    revenue,
    previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue) / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_percent
FROM revenue_with_lag
ORDER BY year, month;
