-- ===================================================
-- 03_return_analysis.sql
-- Return behaviour investigation
--
-- Focus Area:
-- 1. Identify products driving the January return spike
-- 2. Investigate abnormal return behaviour
-- 3. Distinguish operational reversals from consumer returns
-- ===================================================

-- 1. Top January returned products, excluding non-product stock code ('M', 'POST', 'DOT', 'ADJUST', 'D')
WITH january_returns AS (
    SELECT
        StockCode,
        Description,
        ABS(Quantity) AS units_returned,
        Price
    FROM online_retail_ii
    WHERE Quantity < 0
      AND Invoice LIKE 'C%'
      AND YEAR(InvoiceDate) = 2011
      AND MONTH(InvoiceDate) = 1
      AND Description IS NOT NULL
      AND Description <> ''
      AND StockCode NOT IN ('M', 'POST', 'DOT', 'ADJUST', 'D')
      AND StockCode NOT LIKE 'AMAZONFEE%'
      AND StockCode NOT LIKE 'BANK CHARGES%'
)
SELECT
    StockCode,
    Description,
    SUM(units_returned) AS units_returned,
    ROUND(AVG(Price), 2) AS avg_price,
    ROUND(SUM(units_returned * Price), 2) AS return_value
FROM january_returns
GROUP BY StockCode, Description
ORDER BY units_returned DESC
LIMIT 20;

-- Observation:
-- StockCode 23166 appears as an extreme outlier with 74,215 units returned.
-- The next highest SKU has fewer than 100 units returned, suggesting abnormal behaviour.

-- 2. Investigate suspicious StockCode 23166, Check if theres many invoices containing StockCode 231666 or a single reversal for january 2011 return spike 
-- ===================================================
SELECT
    COUNT(DISTINCT Invoice) AS num_invoices,
    MIN(Quantity) AS min_qty,
    MAX(ABS(Quantity)) AS max_abs_qty,
    SUM(ABS(Quantity)) AS total_units_returned
FROM online_retail_ii
WHERE StockCode = '23166'
  AND YEAR(InvoiceDate) = 2011
  AND MONTH(InvoiceDate) = 1
  AND Quantity < 0;
-- SKU 23166 returns is in a singular invoice.

-- 3. Review sales vs returns history for SKU 23166 
SELECT
    YEAR(InvoiceDate) AS year,
    MONTH(InvoiceDate) AS month,
    SUM(CASE WHEN Quantity > 0 THEN Quantity ELSE 0 END) AS units_sold,
    SUM(CASE WHEN Quantity < 0 THEN ABS(Quantity) ELSE 0 END) AS units_returned
FROM online_retail_ii
WHERE StockCode = '23166'
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY year, month;

-- Findings 
-- January 2011 returns for StockCode item '23166' is a huge outlier. Compared to the second highest return unit being 94. 
-- supporting the operational reversal hypothesis.

-- 4. Return concertration, opertional vs consumer returns. 
SELECT 
    StockCode,
    COUNT(DISTINCT Invoice) AS invoice_count,
    SUM(ABS(Quantity)) AS units_returned,
    ROUND(SUM(ABS(Quantity) * Price), 2) AS return_value,
    ROUND(SUM(ABS(Quantity)) / NULLIF(COUNT(DISTINCT Invoice), 0), 2) AS units_per_invoice
FROM online_retail_ii
WHERE Quantity < 0
  AND YEAR(InvoiceDate) = 2011
  AND MONTH(InvoiceDate) = 1
GROUP BY StockCode
ORDER BY units_returned DESC
LIMIT 20;

-- 5. Top return invoices during january 2011
SELECT 
    Invoice,
    COUNT(DISTINCT StockCode) AS sku_count,
    SUM(ABS(Quantity)) AS total_units_returned,
    ROUND(SUM(ABS(Quantity) * Price), 2) AS total_value
FROM online_retail_ii
WHERE Quantity < 0
  AND YEAR(InvoiceDate) = 2011
  AND MONTH(InvoiceDate) = 1
GROUP BY Invoice
ORDER BY total_units_returned DESC
LIMIT 10;

-- 6. Consumer returns during january 2011 
SELECT 
    StockCode,
    COUNT(DISTINCT Invoice) AS invoice_count,
    SUM(ABS(Quantity)) AS units_returned,
    ROUND(SUM(ABS(Quantity) * Price), 2) AS return_value,
    ROUND(SUM(ABS(Quantity)) / NULLIF(COUNT(DISTINCT Invoice), 0), 2) AS units_per_invoice
FROM online_retail_ii
WHERE Quantity < 0
  AND YEAR(InvoiceDate) = 2011
  AND MONTH(InvoiceDate) = 1
GROUP BY StockCode
HAVING COUNT(DISTINCT Invoice) >= 10
   AND ROUND(SUM(ABS(Quantity)) / NULLIF(COUNT(DISTINCT Invoice), 0), 2) <= 10
ORDER BY return_value DESC;

-- 7. Consumer Returns during (OCT-DEC) 
SELECT 
    StockCode,
    COUNT(DISTINCT Invoice) AS invoice_count,
    SUM(ABS(Quantity)) AS units_returned,
    ROUND(SUM(ABS(Quantity) * Price), 2) AS return_value,
    ROUND(SUM(ABS(Quantity)) / NULLIF(COUNT(DISTINCT Invoice), 0), 2) AS units_per_invoice
FROM online_retail_ii
WHERE Quantity < 0
  AND YEAR(InvoiceDate) IN (2010, 2011)
  AND MONTH(InvoiceDate) IN (10,11,12)
GROUP BY StockCode
HAVING COUNT(DISTINCT Invoice) >= 10
   AND ROUND(SUM(ABS(Quantity)) / NULLIF(COUNT(DISTINCT Invoice), 0), 2) <= 10
ORDER BY return_value DESC;
