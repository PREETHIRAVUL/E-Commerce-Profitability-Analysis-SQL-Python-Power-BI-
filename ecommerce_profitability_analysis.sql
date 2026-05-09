select * from ecommerce;

SET SQL_SAFE_UPDATES = 0;
UPDATE ecommerce
SET `Order_Date` = STR_TO_DATE(`Order_Date`, '%d-%m-%Y');

ALTER TABLE ecommerce
CHANGE COLUMN `Order _ID` order_id VARCHAR(50),
CHANGE COLUMN `Order_Date` order_date DATE,
CHANGE COLUMN `Customer_ID` customer_id VARCHAR(50),
CHANGE COLUMN `Segment` segment VARCHAR(50),
CHANGE COLUMN `City` city VARCHAR(100),
CHANGE COLUMN `State` state VARCHAR(100),
CHANGE COLUMN `Country` country VARCHAR(100),
CHANGE COLUMN `Country latitude` country_latitude DECIMAL(10,6),
CHANGE COLUMN `Country longitude` country_longitude DECIMAL(10,6),
CHANGE COLUMN `Region` region VARCHAR(100),
CHANGE COLUMN `Market` market VARCHAR(100),
CHANGE COLUMN `Subcategory` subcategory VARCHAR(150),
CHANGE COLUMN `Category` category VARCHAR(100),
CHANGE COLUMN `Product` product VARCHAR(255),
CHANGE COLUMN `Quantity` quantity INT,
CHANGE COLUMN `Sales` sales DECIMAL(12,2),
CHANGE COLUMN `Discount` discount DECIMAL(5,2),
CHANGE COLUMN `Profit` profit DECIMAL(15,2);


# What is the overall sales, demand, profit, and discount profile of the business?

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(*) AS total_line_items,
    SUM(quantity) AS total_units_sold,

    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS overall_profit_margin_pct,

    ROUND(AVG(discount), 2) AS average_discount_pct,
    ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,
    ROUND(SUM(quantity) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_units_per_order
FROM ecommerce;

#How do demand, revenue, and profit change over time month by month?


SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct
FROM ecommerce
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

#Which product groups drive the most demand, revenue, and profit?


SELECT
    category,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) , 2) AS avg_discount_pct
FROM ecommerce
GROUP BY category
ORDER BY total_revenue DESC;

#Which regions or markets contribute the most to demand, revenue, and profit?


SELECT
    region,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) , 2) AS avg_discount_pct
FROM ecommerce
GROUP BY region
ORDER BY total_revenue DESC;

#Which discount levels increase demand efficiently, and which ones destroy profit?


SELECT
    CASE 
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 = 0 THEN '0%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0 AND CAST(REPLACE(discount, '%','') AS DECIMAL)/100 <= 0.10 THEN '0-10%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0.10 AND CAST(REPLACE(discount, '%','') AS DECIMAL)/100 <= 0.20 THEN '10-20%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0.20 AND CAST(REPLACE(discount, '%','') AS DECIMAL)/100 <= 0.30 THEN '20-30%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0.30 AND CAST(REPLACE(discount, '%','') AS DECIMAL)/100 <= 0.40 THEN '30-40%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0.40 AND CAST(REPLACE(discount, '%','') AS DECIMAL)/100 <= 0.50 THEN '40-50%'
        WHEN CAST(REPLACE(discount, '%','') AS DECIMAL)/100 > 0.50 THEN '>50%'
    END AS discount_band,

    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS profit_margin_pct,
    ROUND(AVG(quantity),2) AS avg_units_per_order,
    ROUND(AVG(sales),2) AS avg_order_value

FROM ecommerce
GROUP BY discount_band
ORDER BY 
    CASE 
        WHEN discount_band = '0%' THEN 1
        WHEN discount_band = '0-10%' THEN 2
        WHEN discount_band = '10-20%' THEN 3
        WHEN discount_band = '20-30%' THEN 4
        WHEN discount_band = '30-40%' THEN 5
        WHEN discount_band = '40-50%' THEN 6
        WHEN discount_band = '>50%' THEN 7
    END;
    
    # At what discount range does profitability begin to break down?
    
    
    SELECT
    bucket_start,
    CONCAT(bucket_start, '% - ', bucket_start + 5, '%') AS discount_bucket,
    total_line_items,
    total_orders,
    total_units_sold,
    total_revenue,
    total_profit,
    profit_margin_pct,
    avg_discount_pct
FROM (
    SELECT
        FLOOR((discount) / 5) * 5 AS bucket_start,
        COUNT(*) AS total_line_items,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS total_units_sold,
        ROUND(SUM(sales), 2) AS total_revenue,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
        ROUND(AVG(discount) , 2) AS avg_discount_pct
    FROM ecommerce
    GROUP BY FLOOR((discount * 100) / 5) * 5
) t
ORDER BY bucket_start;
SELECT
    discount,
    COUNT(*) AS row_count
FROM ecommerce
GROUP BY discount
ORDER BY discount;

#Which products or subcategories generate revenue but fail to convert that demand into profit?

SELECT
    category,
    subcategory,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) , 2) AS avg_discount_pct
FROM ecommerce
GROUP BY category, subcategory
HAVING SUM(sales) > 0
ORDER BY total_revenue DESC, total_profit ASC;


# Were low-profit months associated with heavier discounting?


SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) , 2) AS avg_discount_pct
FROM ecommerce
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

SELECT 
    category,
    
    CASE 
        WHEN discount = 0 THEN '0%'
        WHEN discount <= 0.1 THEN '0-10%'
        WHEN discount <= 0.2 THEN '10-20%'
        WHEN discount <= 0.3 THEN '20-30%'
        WHEN discount <= 0.4 THEN '30-40%'
        ELSE '40%+'
    END AS discount_band,

    COUNT(*) AS total_orders,
    ROUND(SUM(sales),2) AS revenue,
    ROUND(SUM(profit),2) AS profit,
    ROUND(AVG(profit),2) AS avg_profit,
    ROUND(AVG(profit/sales)*100,2) AS margin_pct,

    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_orders

FROM ecommerce
GROUP BY category, discount_band
ORDER BY category, discount_band;



SELECT 
    FLOOR(discount  / 5) * 5 AS discount_start,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(AVG(profit),2) AS avg_profit,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_orders
FROM ecommerce
GROUP BY FLOOR(discount  / 5) * 5
ORDER BY discount_start;


    