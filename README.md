# Data Warehouse Project (PostgreSQL + Python | Star Schema + SCD Type 2)

## Tools I used
- **PostgreSQL** – database + star schema design  
- **Python** – Script for staging loads  
- **Pandas + psycopg2** – for CSV ingestion, database connectivity and queries

---

## Project Overview
I had a CSV file with order data and created a database, five dimension tables and one fact table in PostgreSQL.  
My main goal was to:
- Build a **Star Schema**  
- Implement **Slowly Changing Dimension (SCD) Type 2**
- Answer important business questions

---

## Star Schema Entity-Relationship Diagram

<div align="center">
  <img width="694" alt="Screenshot1" src="https://github.com/aakshatha02/Star-Schema-Dimension-Modeling/blob/main/star_schema_ERD.png">
</div>

## Steps I followed
1. First I created the Database named as **retail_db** in PostgreSQL

2. **Staging Table**  
   - Later, I loaded the raw CSV into a table called `staging_sales` using a Python script.  
   - The script:  
     - Connects to PostgreSQL using psycopg2 library
     - Truncates the staging table before each load  
     - Inserts fresh CSV data  

3. **Creating the Star Schema**  
   From the staging table (denormalized), I created:  
   - **5 dimension tables**:  
     - `dim_customers`  
     - `dim_products`  
     - `dim_shippers`  
     - `dim_order_statuses`  
     - `dim_order_date`  
   - **1 fact table**:  
     - `fact_sales`  

---

## SCD Type 2 (dim_customers)
I implemented Slowly Changing Dimension logic in `dim_customers`.  

**Example:**  
- Customer *Sarah* lived in **NY / Santosstad** and made 5 orders.  
  - In `dim_customers`, her row has `start_date`, `end_date = NULL`, and `is_current = TRUE`.  
- Later, she moved to **MA / Boston** and made 1 order.  
  - The old row in `dim_customers` is updated → `end_date = new_order_date - 1`, `is_current = FALSE`.  
  - A **new row** is inserted with `start_date = new_order_date`, `end_date = NULL`, `is_current = TRUE`.  
- The **customer_key** changes, and this is updated in the `fact_sales` table.  
  - This way, we can **differentiate orders by old vs new address** and track history correctly.  

---

## Business Questions My Model Can Answer
Using the star schema and SCD Type 2 implementation, this data warehouse can answer questions such as:
- How are sales changing month over month?
- Which products have declining sales trends?
- How many unique customers placed orders in a given time period?
- Which products generate the most revenue?
- Historical Tracking (via SCD2): How many customers moved from one region to another, and what impact did that have on sales?
- Which shippers handle the most orders?
- What’s the average order size per product?
- What is the total sales amount and quantity sold (customer,daily, monthly, yearly)?
- How many orders are completed, pending, or canceled?

Queries for all these question can found here [business_question_ans.ipynb](https://github.com/aakshatha02/Star-Schema-Dimension-Modeling/blob/main/business_question_ans.ipynb)
---
## SQL DDL & Sample Data
The SQL scripts to create schema and insert sample data are here:  
- [star_schema.sql](https://github.com/aakshatha02/Star-Schema-Dimension-Modeling/blob/main/star_schema.sql)
- [scd_type2.sql](https://github.com/aakshatha02/Star-Schema-Dimension-Modeling/blob/main/scd_type2.sql)
