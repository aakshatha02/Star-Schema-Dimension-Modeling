-- =======================
-- DIM_CUSTOMERS
-- =======================
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_key   BIGSERIAL PRIMARY KEY,     -- surrogate key
    customer_id    INT NOT NULL,              
    first_name     VARCHAR(50),
    last_name      VARCHAR(50),
    city           VARCHAR(50),
    state          CHAR(2),
    start_date     DATE NOT NULL,            
    end_date       DATE,                     
    is_current     BOOLEAN NOT NULL DEFAULT TRUE, 
    CONSTRAINT uq_customer_version UNIQUE (customer_id, start_date)
);

--  during initial load

INSERT INTO dim_customers (
    customer_id, first_name, last_name, city, state,
    start_date, end_date, is_current
)
SELECT 
    s.customer_id,
    s.first_name,
    s.last_name,
    s.city,
    s.state,
    MIN(s.order_date) AS start_date,   
    NULL::DATE AS end_date,
    TRUE AS is_current
FROM staging_sales s
GROUP BY s.customer_id, s.first_name, s.last_name, s.city, s.state;


-- =======================
-- DIM_PRODUCTS
-- =======================
CREATE TABLE IF NOT EXISTS dim_products (
    product_key BIGSERIAL PRIMARY KEY,
    product_id INT UNIQUE,
    product_name VARCHAR(100),
    unit_price DECIMAL(10,2)
);

INSERT INTO dim_products(product_id, product_name, unit_price)
SELECT DISTINCT s.product_id, s.product_name, s.unit_price
FROM staging_sales s
ON CONFLICT (product_id) DO NOTHING;


-- =======================
-- DIM_SHIPPERS
-- =======================
CREATE TABLE IF NOT EXISTS dim_shippers (
    shipper_key BIGSERIAL PRIMARY KEY,
    shipper_id INT UNIQUE,
    shipper_name VARCHAR(100)
);

INSERT INTO dim_shippers(shipper_id, shipper_name)
SELECT DISTINCT s.shipper_id, s.shipper_name
FROM staging_sales s
ON CONFLICT (shipper_id) DO NOTHING;


-- =======================
-- DIM_ORDER_STATUSES
-- =======================
CREATE TABLE IF NOT EXISTS dim_order_statuses (
    order_status_key BIGSERIAL PRIMARY KEY,
    order_status_id INT UNIQUE,
    order_status VARCHAR(50)
);

INSERT INTO dim_order_statuses(order_status_id, order_status)
SELECT DISTINCT s.order_status_id, s.order_status
FROM staging_sales s
ON CONFLICT (order_status_id) DO NOTHING;


-- =======================
-- DIM_ORDER_DATE
-- =======================
CREATE TABLE IF NOT EXISTS dim_order_date (
    date_key BIGSERIAL PRIMARY KEY,
    order_date DATE UNIQUE,
    order_year INT,
    order_month INT,
    order_day INT
);

INSERT INTO dim_order_date (order_date, order_year, order_month, order_day)
SELECT DISTINCT s.order_date,
       EXTRACT(YEAR FROM s.order_date)::INT,
       EXTRACT(MONTH FROM s.order_date)::INT,
       EXTRACT(DAY FROM s.order_date)::INT
FROM staging_sales s
ON CONFLICT (order_date) DO NOTHING;


-- =======================
-- FACT_SALES
-- =======================
CREATE TABLE IF NOT EXISTS fact_sales (
    order_id INT,  
    customer_key BIGINT,
    product_key BIGINT,
    shipper_key BIGINT,
    order_status_key BIGINT,
    date_key BIGINT,
    quantity INT,
    unit_price DECIMAL(10,2),
    PRIMARY KEY(order_id, product_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customers(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_products(product_key),
    FOREIGN KEY (shipper_key) REFERENCES dim_shippers(shipper_key),
    FOREIGN KEY (order_status_key) REFERENCES dim_order_statuses(order_status_key),
    FOREIGN KEY (date_key) REFERENCES dim_order_date(date_key)
);

INSERT INTO fact_sales (
    order_id, customer_key, product_key, shipper_key, order_status_key, date_key,
    quantity, unit_price
)
SELECT
    s.order_id,
    dc.customer_key,
    dp.product_key,
    ds.shipper_key,
    dos.order_status_key,
    dd.date_key,
    s.quantity,
    s.unit_price
FROM staging_sales s
JOIN dim_products       dp  ON s.product_id      = dp.product_id
JOIN dim_shippers       ds  ON s.shipper_id      = ds.shipper_id
JOIN dim_order_statuses dos ON s.order_status_id = dos.order_status_id
JOIN dim_order_date     dd  ON s.order_date      = dd.order_date
JOIN dim_customers dc
  ON s.customer_id = dc.customer_id
 AND s.order_date >= dc.start_date
 AND s.order_date <  COALESCE(dc.end_date, DATE '9999-12-31')
ON CONFLICT (order_id, product_key) DO UPDATE
  SET quantity   = EXCLUDED.quantity,
     unit_price = EXCLUDED.unit_price;
