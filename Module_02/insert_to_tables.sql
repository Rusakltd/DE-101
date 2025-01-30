--- 1. Insert into Shipping
insert into shipping
select 100+row_number() over (), 
ship_mode from (select distinct ship_mode from orders) a;

--- 2. Insert into Geography
INSERT INTO geography (geo_id, postal_code, city, state, region, country)
SELECT 
    100000 + ROW_NUMBER() over (),
    postal_code,
    city,
    state,
    region,
    country
FROM orders
group by postal_code, city, state, region, country
having postal_code is not null;

--- 3. Insert Calendar
-- Change to numeric
ALTER TABLE calendar
	ALTER COLUMN year TYPE numeric USING lower(year)::numeric;
	ALTER COLUMN month TYPE numeric USING lower(month)::numeric;
	ALTER COLUMN week TYPE numeric USING lower(week)::numeric;
	ALTER COLUMN week_day TYPE numeric USING lower(week_day)::numeric;

--- Insert into Calendar
INSERT INTO calendar (order_date, ship_date, year, quarter, month, week, week_day)
SELECT DISTINCT
    order_date,
    ship_date,
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(QUARTER FROM order_date) AS quarter,
    EXTRACT(MONTH FROM order_date) AS month,
    EXTRACT(WEEK FROM order_date) AS week,
    EXTRACT(DOW FROM order_date) AS week_day
FROM orders
ON CONFLICT (order_date, ship_date) DO NOTHING; -- Skip composite key already exists

--- 4. Insert into Product
INSERT INTO product (product_id, category, subcategory, segment, product_name)
	select distinct product_id, category, subcategory, segment, product_name
	from orders o
ON CONFLICT (product_id) DO NOTHING;

--- 5. Insert into Customer
INSERT INTO customer (order_id, sales, quantity, discount, profit, geo_id, 
    order_date, ship_id, product_id, ship_date)
SELECT 
    order_id,
    sales,
    quantity,
    discount,
    profit,
    geo_id, 
    order_date,
    ship_id,
    product_id,
    ship_date
    from orders o;

--- 6. Insert into Sales
INSERT INTO sales (row_id, order_id, sales, quantity, discount, profit, geo_id, 
    order_date, ship_id, product_id, ship_date)
SELECT 
    int4range(o.row_id, o.row_id + 1, '[)'), 
    o.order_id,
    o.sales,
    int4range(o.quantity, o.quantity + 1, '[)'),
    o.discount,
    o.profit,
    g.geo_id, 
    o.order_date,
    s.ship_id,
    o.product_id,
    o.ship_date
FROM orders o
LEFT JOIN geography g
    ON g.postal_code = o.postal_code 
    AND o.city = g.city
LEFT JOIN shipping s
    ON o.ship_mode = s.ship_mode 
WHERE o.postal_code IS NOT NULL;