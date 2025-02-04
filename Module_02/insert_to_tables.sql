--- 1. Insert into Shipping
insert into shipping
select 100+row_number() over (), 
ship_mode from (select distinct ship_mode from orders) a;

--- 2. Insert into Geography
INSERT INTO geography (geo_id, country, city, state, region, postal_code)
SELECT 
    100000 + ROW_NUMBER() over (),
    country,
    city,
    state,
    region,
    postal_code
FROM (select distinct country, city, state, postal_code from orders) a;

-- Fix postal_code
UPDATE geography
SET postal_code = '05401'
where city = 'Burlington' and state = 'Vermont' and postal_code is null;

--- 3. Insert Calendar
-- Change to numeric
insert into calendar
select 
to_char(date,'yyyymmdd')::int as dateid,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       date::date,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);

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