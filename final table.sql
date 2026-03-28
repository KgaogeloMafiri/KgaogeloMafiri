ALTER DATABASE postgres SET datestyle TO 'ISO, MDY';

-- 1. Create the Product table first (The Parent)
CREATE TABLE public.product_data (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    cost_price TEXT, 
    sale_price TEXT,
    brand TEXT,
    description TEXT,
    image_url TEXT
);

-- 2. Create the Discount table
CREATE TABLE public.discount_data (
    month VARCHAR(20),
    discount_band TEXT,
    discount INT
);


-- 3. Create the Sales table last (The Child)
CREATE TABLE public.product_sales (
    sale_date DATE,
    customer_type TEXT,
    country TEXT,
    product_id VARCHAR(50) REFERENCES public.product_data(product_id),
    discount_band TEXT,
    units_sold INT
);

ALTER TABLE public.product_data 
    ALTER COLUMN cost_price TYPE NUMERIC 
        USING (REPLACE(REPLACE(cost_price::text, '$', ''), ',', '')::NUMERIC),
    ALTER COLUMN sale_price TYPE NUMERIC 
        USING (REPLACE(REPLACE(sale_price::text, '$', ''), ',', '')::NUMERIC);
		
WITH cte AS (
    SELECT 
        a.product_name,
        a.category,
        a.brand,
        a.cost_price,
        a.sale_price,
        b.units_sold,
        b.sale_date,
        b.country,
        b.discount_band,
        (a.cost_price * b.units_sold) AS total_costs,
        (a.sale_price * b.units_sold) AS gross_revenue,
        TRIM(TO_CHAR(b.sale_date, 'FMMonth')) AS sale_month
    FROM public.product_data a
    JOIN public.product_sales b ON a.product_id = b.product_id
)
SELECT 
    c.*,
    COALESCE(d.discount, 0) AS discount_percent,
    -- Calculate Net Revenue (Revenue after discount)
    (c.gross_revenue * (1 - COALESCE(d.discount, 0)::numeric/100)) AS net_revenue,
    -- Calculate Profit
    ((c.gross_revenue * (1 - COALESCE(d.discount, 0)::numeric/100)) - c.total_costs) AS net_profit
FROM cte c
LEFT JOIN public.discount_data d 
    ON c.sale_month = d.month 
    AND c.discount_band = d.discount_band;


SELECT 
    (SELECT COUNT(*) FROM product_data) as products_count,
    (SELECT COUNT(*) FROM product_sales) as sales_count,
    (SELECT COUNT(*) FROM discount_data) as discounts_count;	