---dim_customer to upadte with SCD2---
UPDATE dim_customers d
SET end_date   = CURRENT_DATE - INTERVAL '1 day',
    is_current = FALSE
FROM (
    SELECT DISTINCT ON (customer_id)
           customer_id, first_name, last_name, city, state
    FROM staging_sales
    ORDER BY customer_id, order_date DESC
) s
WHERE d.customer_id = s.customer_id
  AND d.is_current = TRUE
  AND (
       d.first_name <> s.first_name
    OR d.last_name  <> s.last_name
    OR d.city       <> s.city
    OR d.state      <> s.state
  );
---dim_customer---
INSERT INTO dim_customers (
    customer_id, first_name, last_name, city, state,
    start_date, end_date, is_current
)
SELECT DISTINCT ON (s.customer_id)
    s.customer_id,
    s.first_name,
    s.last_name,
    s.city,
    s.state,
    CURRENT_DATE,
    NULL::DATE,
    TRUE
FROM staging_sales s
LEFT JOIN dim_customers d
       ON d.customer_id = s.customer_id
      AND d.is_current = TRUE
WHERE d.customer_id IS NULL 
   OR (
       d.first_name <> s.first_name
    OR d.last_name  <> s.last_name
    OR d.city       <> s.city
    OR d.state      <> s.state
   )
ORDER BY s.customer_id, s.order_date DESC
ON CONFLICT (customer_id, start_date) DO NOTHING;
