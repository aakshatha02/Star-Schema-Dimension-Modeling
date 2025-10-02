import pandas as pd
import psycopg2

# --- 2. Connect to PostgreSQL ---
conn = psycopg2.connect(
    dbname="retaildb",
    user="akshatha",
    password="1Password*",
    host="localhost",
    port="5433"
)
cur = conn.cursor()

cur.execute("""
CREATE TABLE IF NOT EXISTS staging_sales(
    order_id INT,
    order_date DATE,
    shipped_date DATE,
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    city VARCHAR(50),
    state CHAR(2),
    product_id INT,
    product_name VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(10,2),
    shipper_id INT,
    shipper_name VARCHAR(100),
    order_status_id INT,
    order_status VARCHAR(50))
            """)

# Truncate staging table before load
cur.execute("TRUNCATE TABLE staging_sales;")

# Load CSV using COPY
with open('store_sales1.csv', 'r') as f:
    next(f)  # Skip header row
    cur.copy_from(f, 'staging_sales', sep=',', null="")

conn.commit()
cur.close()
conn.close()