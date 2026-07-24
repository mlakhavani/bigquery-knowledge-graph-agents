# BigQuery & Spanner Property Graph & GQL Queries

We have successfully defined and deployed a Labeled Property Graph (LPG) named `customer_retail_graph` spanning all tables in the customers and products datasets.

* **BigQuery graph trigger model**: [customer_retail_graph_trigger.sql](file:///Users/mikenimer/Development/github/dsg_vip_customer_agents/data-products/bigquery/dsg_customers/models/customer_retail_graph_trigger.sql).
* **Spanner schema & graph DDL**: [schema.sql](file:///Users/mikenimer/Development/github/dsg_vip_customer_agents/data-products/spanner/dsg_graph/ddl/schema.sql).

---

## 1. Graph DDL Definitions

### BigQuery DDL
```sql
CREATE OR REPLACE PROPERTY GRAPH `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
NODE TABLES (
  `dsg-vip-customer-demo.dsg_customers.customers` AS customer
    KEY (customer_id)
    LABEL customer
    PROPERTIES (customer_id, name, email, phone_number, address, city, state, zip_code, date_joined),
  `dsg-vip-customer-demo.dsg_customers.orders` AS sales_order
    KEY (order_id)
    LABEL sales_order
    PROPERTIES (order_id, customer_id, store_id, order_date, total_amount),
  `dsg-vip-customer-demo.dsg_products.products` AS product
    KEY (sku)
    LABEL product
    PROPERTIES (sku, name, brand, gender, colors, sizes, image_url, description, price, marketing_pdf_url),
  `dsg-vip-customer-demo.dsg_products.stores` AS store
    KEY (store_id)
    LABEL store
    PROPERTIES (store_id, name, address, city, state, zip_code, phone_number),
  `dsg-vip-customer-demo.dsg_customers.customer_health` AS customer_health
    KEY (customer_id, sync_date)
    LABEL customer_health
    PROPERTIES (customer_id, sync_date, device_type, steps_count, calories_burned, avg_heart_rate, active_minutes, sleep_hours)
)
EDGE TABLES (
  `dsg-vip-customer-demo.dsg_customers.orders` AS order_placed_by
    KEY (order_id)
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
    LABEL placed_by,
  `dsg-vip-customer-demo.dsg_customers.orders` AS order_in_store
    KEY (order_id)
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (store_id) REFERENCES store(store_id)
    LABEL in_store,
  `dsg-vip-customer-demo.dsg_customers.order_items` AS order_purchased_product
    KEY (order_id, sku)
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (sku) REFERENCES product(sku)
    LABEL purchased
    PROPERTIES (quantity, price),
  `dsg-vip-customer-demo.dsg_customers.customer_health` AS health_for_customer
    KEY (customer_id, sync_date)
    SOURCE KEY (customer_id, sync_date) REFERENCES customer_health(customer_id, sync_date)
    DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
    LABEL health_for,
  `dsg-vip-customer-demo.dsg_products.inventory` AS store_stocks_product
    KEY (sku, store_id, color, size)
    SOURCE KEY (store_id) REFERENCES store(store_id)
    DESTINATION KEY (sku) REFERENCES product(sku)
    LABEL stocks
    PROPERTIES (color, size, stock_quantity, supply_warehouse, last_updated_at)
);
```

### Spanner DDL
```sql
CREATE PROPERTY GRAPH customer_retail_graph
NODE TABLES (
  customers AS customer
    LABEL customer
    PROPERTIES (customer_id, name, email, phone_number, address, city, state, zip_code, date_joined),
  orders AS sales_order
    LABEL sales_order
    PROPERTIES (order_id, customer_id, store_id, order_date, total_amount),
  products AS product
    LABEL product
    PROPERTIES (sku, name, brand, gender, colors, sizes, image_url, description, price, marketing_pdf_url),
  stores AS store
    LABEL store
    PROPERTIES (store_id, name, address, city, state, zip_code, phone_number),
  customer_health AS customer_health
    LABEL customer_health
    PROPERTIES (customer_id, sync_date, device_type, steps_count, calories_burned, avg_heart_rate, active_minutes, sleep_hours)
)
EDGE TABLES (
  orders AS order_placed_by
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
    LABEL placed_by,
  orders AS order_in_store
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (store_id) REFERENCES store(store_id)
    LABEL in_store,
  order_items AS order_purchased_product
    SOURCE KEY (order_id) REFERENCES sales_order(order_id)
    DESTINATION KEY (sku) REFERENCES product(sku)
    LABEL purchased
    PROPERTIES (quantity, price),
  customer_health AS health_for_customer
    SOURCE KEY (customer_id, sync_date) REFERENCES customer_health(customer_id, sync_date)
    DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
    LABEL health_for,
  inventory AS store_stocks_product
    SOURCE KEY (store_id) REFERENCES store(store_id)
    DESTINATION KEY (sku) REFERENCES product(sku)
    LABEL stocks
    PROPERTIES (color, size, stock_quantity, supply_warehouse, last_updated_at)
);
```

---

## 2. Business Queries (BigQuery & Spanner Versions)

All queries have been successfully verified on the `dsg-vip-customer-demo` project.

### Query 1: Average Order Value (AOV) per Customer by City
* **Question:** Calculate the average order value (AOV) per customer, broken down by their city, for customers who joined before a specific date.
* **BigQuery Query:**
```sql
SELECT 
  customer_city,
  customer_id,
  customer_name,
  AVG(order_amount) AS aov
FROM GRAPH_TABLE(
  `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
  MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
  WHERE c.date_joined < TIMESTAMP('2020-01-01 00:00:00 UTC')
  COLUMNS(
    c.city AS customer_city,
    c.customer_id AS customer_id,
    c.name AS customer_name,
    o.total_amount AS order_amount
  )
)
GROUP BY customer_city, customer_id, customer_name
ORDER BY customer_city, aov DESC;
```
* **Spanner Query:**
```sql
SELECT 
  customer_city,
  customer_id,
  customer_name,
  AVG(order_amount) AS aov
FROM GRAPH_TABLE(
  customer_retail_graph
  MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
  WHERE c.date_joined < TIMESTAMP('2020-01-01 00:00:00 UTC')
  COLUMNS(
    c.city AS customer_city,
    c.customer_id AS customer_id,
    c.name AS customer_name,
    o.total_amount AS order_amount
  )
)
GROUP BY customer_city, customer_id, customer_name
ORDER BY customer_city, aov DESC;
```

---

### Query 2: Correlation Between Steps and Order Amount
* **Question:** Determine the correlation between a customer's average daily steps count and their total order amount, for customers using a 'Fitness Tracker' device.
* **BigQuery Query:**
```sql
WITH customer_orders AS (
  SELECT customer_id, SUM(total_amount) AS total_order_amount
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, o.total_amount AS total_amount)
  )
  GROUP BY customer_id
),
customer_steps AS (
  SELECT customer_id, device_type, AVG(steps_count) AS avg_daily_steps
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.device_type AS device_type, h.steps_count AS steps_count)
  )
  GROUP BY customer_id, device_type
)
SELECT 
  cs.device_type,
  CORR(cs.avg_daily_steps, co.total_order_amount) AS correlation,
  COUNT(*) AS customer_count
FROM customer_steps cs
JOIN customer_orders co ON cs.customer_id = co.customer_id
GROUP BY cs.device_type;
```
* **Spanner Query:**
> [!NOTE]
> Since the `CORR()` aggregation function is not natively supported in Spanner's GoogleSQL dialect, a mathematical formula for the Pearson correlation coefficient is used.
```sql
WITH customer_orders AS (
  SELECT customer_id, SUM(total_amount) AS total_order_amount
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, o.total_amount AS total_amount)
  )
  GROUP BY customer_id
),
customer_steps AS (
  SELECT customer_id, device_type, AVG(steps_count) AS avg_daily_steps
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.device_type AS device_type, h.steps_count AS steps_count)
  )
  GROUP BY customer_id, device_type
),
combined_data AS (
  SELECT 
    cs.device_type,
    cs.avg_daily_steps AS x,
    CAST(co.total_order_amount AS FLOAT64) AS y
  FROM customer_steps cs
  JOIN customer_orders co ON cs.customer_id = co.customer_id
)
SELECT 
  device_type,
  (COUNT(*) * SUM(x * y) - SUM(x) * SUM(y)) /
  SQRT((COUNT(*) * SUM(x * x) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(y * y) - SUM(y) * SUM(y))) AS correlation,
  COUNT(*) AS customer_count
FROM combined_data
GROUP BY device_type;
```

---

### Query 3: Top Spending Customers with Heart Rate > 80
* **Question:** Find the top 5 customers with the highest total spending who also have an average heart rate above 80, along with their average sleep hours.
* **BigQuery Query:**
```sql
WITH customer_spending AS (
  SELECT customer_id, customer_name, SUM(total_amount) AS total_spending
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, c.name AS customer_name, o.total_amount AS total_amount)
  )
  GROUP BY customer_id, customer_name
),
customer_health_metrics AS (
  SELECT 
    customer_id, 
    AVG(avg_heart_rate) AS avg_heart_rate, 
    AVG(sleep_hours) AS avg_sleep_hours
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.avg_heart_rate AS avg_heart_rate, h.sleep_hours AS sleep_hours)
  )
  GROUP BY customer_id
)
SELECT 
  cs.customer_name,
  cs.total_spending,
  ch.avg_heart_rate,
  ch.avg_sleep_hours
FROM customer_spending cs
JOIN customer_health_metrics ch ON cs.customer_id = ch.customer_id
WHERE ch.avg_heart_rate > 80
ORDER BY cs.total_spending DESC
LIMIT 5;
```
* **Spanner Query:**
```sql
WITH customer_spending AS (
  SELECT customer_id, customer_name, SUM(total_amount) AS total_spending
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, c.name AS customer_name, o.total_amount AS total_amount)
  )
  GROUP BY customer_id, customer_name
),
customer_health_metrics AS (
  SELECT 
    customer_id, 
    AVG(avg_heart_rate) AS avg_heart_rate, 
    AVG(sleep_hours) AS avg_sleep_hours
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.avg_heart_rate AS avg_heart_rate, h.sleep_hours AS sleep_hours)
  )
  GROUP BY customer_id
)
SELECT 
  cs.customer_name,
  cs.total_spending,
  ch.avg_heart_rate,
  ch.avg_sleep_hours
FROM customer_spending cs
JOIN customer_health_metrics ch ON cs.customer_id = ch.customer_id
WHERE ch.avg_heart_rate > 80
ORDER BY cs.total_spending DESC
LIMIT 5;
```

---

### Query 4: Multi-State Customers & Active Minutes
* **Question:** Identify customers who have placed orders in more than one state and calculate their average active minutes.
* **BigQuery Query:**
```sql
WITH customer_order_states AS (
  SELECT 
    customer_id,
    customer_name,
    COUNT(DISTINCT store_state) AS state_count
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (c:customer)<-[:placed_by]-(o:sales_order)-[:in_store]->(s:store)
    COLUMNS(c.customer_id AS customer_id, c.name AS customer_name, s.state AS store_state)
  )
  GROUP BY customer_id, customer_name
  HAVING state_count > 1
),
customer_health_active AS (
  SELECT 
    customer_id, 
    AVG(active_minutes) AS avg_active_minutes
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.active_minutes AS active_minutes)
  )
  GROUP BY customer_id
)
SELECT 
  cos.customer_name,
  cos.state_count,
  cha.avg_active_minutes
FROM customer_order_states cos
JOIN customer_health_active cha ON cos.customer_id = cha.customer_id
ORDER BY cos.state_count DESC, cha.avg_active_minutes DESC
LIMIT 5;
```
* **Spanner Query:**
```sql
WITH customer_order_states AS (
  SELECT 
    customer_id,
    customer_name,
    COUNT(DISTINCT store_state) AS state_count
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (c:customer)<-[:placed_by]-(o:sales_order)-[:in_store]->(s:store)
    COLUMNS(c.customer_id AS customer_id, c.name AS customer_name, s.state AS store_state)
  )
  GROUP BY customer_id, customer_name
  HAVING state_count > 1
),
customer_health_active AS (
  SELECT 
    customer_id, 
    AVG(active_minutes) AS avg_active_minutes
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id AS customer_id, h.active_minutes AS active_minutes)
  )
  GROUP BY customer_id
)
SELECT 
  cos.customer_name,
  cos.state_count,
  cha.avg_active_minutes
FROM customer_order_states cos
JOIN customer_health_active cha ON cos.customer_id = cha.customer_id
ORDER BY cos.state_count DESC, cha.avg_active_minutes DESC
LIMIT 5;
```

---

### Query 5: Customer with Highest Calories Burned & At Least 3 Orders
* **Question:** Find the customer with the highest total calories burned who has also made at least 3 orders, and show their total spending.
* **BigQuery Query:**
```sql
WITH customer_orders AS (
  SELECT 
    customer_id, 
    COUNT(order_id) AS order_count, 
    SUM(total_amount) AS total_spending
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id, o.order_id, o.total_amount)
  )
  GROUP BY customer_id
),
customer_health_calories AS (
  SELECT 
    customer_id, 
    customer_name,
    SUM(calories_burned) AS total_calories_burned
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id, c.name AS customer_name, h.calories_burned)
  )
  GROUP BY customer_id, customer_name
)
SELECT 
  chc.customer_name,
  chc.total_calories_burned,
  co.order_count,
  co.total_spending
FROM customer_health_calories chc
JOIN customer_orders co ON chc.customer_id = co.customer_id
WHERE co.order_count >= 3
ORDER BY chc.total_calories_burned DESC
LIMIT 1;
```
* **Spanner Query:**
```sql
WITH customer_orders AS (
  SELECT 
    customer_id, 
    COUNT(order_id) AS order_count, 
    SUM(total_amount) AS total_spending
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (o:sales_order)-[pb:placed_by]->(c:customer)
    COLUMNS(c.customer_id, o.order_id, o.total_amount)
  )
  GROUP BY customer_id
),
customer_health_calories AS (
  SELECT 
    customer_id, 
    customer_name,
    SUM(calories_burned) AS total_calories_burned
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (h:customer_health)-[hf:health_for]->(c:customer)
    COLUMNS(c.customer_id, c.name AS customer_name, h.calories_burned)
  )
  GROUP BY customer_id, customer_name
)
SELECT 
  chc.customer_name,
  chc.total_calories_burned,
  co.order_count,
  co.total_spending
FROM customer_health_calories chc
JOIN customer_orders co ON chc.customer_id = co.customer_id
WHERE co.order_count >= 3
ORDER BY chc.total_calories_burned DESC
LIMIT 1;
```

---

### Query 6: Average Stock and Price of Products with Marketing PDFs
* **Question:** Calculate the average stock quantity and average price for products, grouped by brand and gender, for products that have a marketing PDF URL.
* **BigQuery Query:**
```sql
SELECT 
  brand,
  gender,
  AVG(stock_quantity) AS avg_stock_quantity,
  AVG(price) AS avg_price
FROM GRAPH_TABLE(
  `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.marketing_pdf_url IS NOT NULL AND p.marketing_pdf_url != ''
  COLUMNS(p.brand, p.gender, st.stock_quantity, p.price)
)
GROUP BY brand, gender
ORDER BY brand, gender;
```
* **Spanner Query:**
```sql
SELECT 
  brand,
  gender,
  AVG(stock_quantity) AS avg_stock_quantity,
  AVG(price) AS avg_price
FROM GRAPH_TABLE(
  customer_retail_graph
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.marketing_pdf_url IS NOT NULL AND p.marketing_pdf_url != ''
  COLUMNS(p.brand, p.gender, st.stock_quantity, p.price)
)
GROUP BY brand, gender
ORDER BY brand, gender;
```

---

### Query 7: Total Stock Value per Store (Product Price > $50)
* **Question:** Determine the total stock value per store, considering only products with a price greater than $50, and order by the highest total stock value.
* **BigQuery Query:**
```sql
SELECT 
  store_name,
  store_city,
  store_state,
  SUM(stock_quantity * product_price) AS total_stock_value
FROM GRAPH_TABLE(
  `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.price > 50
  COLUMNS(s.name AS store_name, s.city AS store_city, s.state AS store_state, st.stock_quantity, p.price AS product_price)
)
GROUP BY store_name, store_city, store_state
ORDER BY total_stock_value DESC;
```
* **Spanner Query:**
```sql
SELECT 
  store_name,
  store_city,
  store_state,
  SUM(stock_quantity * product_price) AS total_stock_value
FROM GRAPH_TABLE(
  customer_retail_graph
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.price > 50
  COLUMNS(s.name AS store_name, s.city AS store_city, s.state AS store_state, st.stock_quantity, p.price AS product_price)
)
GROUP BY store_name, store_city, store_state
ORDER BY total_stock_value DESC;
```

---

### Query 8: Top 5 Cities with Highest Avg Product Price (With Images)
* **Question:** Identify the top 5 cities with the highest average product price across all stores, considering only products that have an image URL.
* **BigQuery Query:**
```sql
SELECT 
  store_city,
  AVG(product_price) AS avg_product_price
FROM GRAPH_TABLE(
  `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.image_url IS NOT NULL AND p.image_url != ''
  COLUMNS(s.city AS store_city, p.price AS product_price)
)
GROUP BY store_city
ORDER BY avg_product_price DESC
LIMIT 5;
```
* **Spanner Query:**
```sql
SELECT 
  store_city,
  AVG(product_price) AS avg_product_price
FROM GRAPH_TABLE(
  customer_retail_graph
  MATCH (s:store)-[st:stocks]->(p:product)
  WHERE p.image_url IS NOT NULL AND p.image_url != ''
  COLUMNS(s.city AS store_city, p.price AS product_price)
)
GROUP BY store_city
ORDER BY avg_product_price DESC
LIMIT 5;
```

---

### Query 9: Correlation Between Product Price and Stock Quantity per Brand
* **Question:** Calculate the coefficient of correlation between product price and stock quantity for each brand, considering only products available in more than one store.
* **BigQuery Query:**
```sql
WITH products_in_multiple_stores AS (
  SELECT sku
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(s.store_id, p.sku)
  )
  GROUP BY sku
  HAVING COUNT(DISTINCT store_id) > 1
),
product_stock_data AS (
  SELECT brand, price, stock_quantity
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(p.sku, p.brand, p.price, st.stock_quantity)
  )
  WHERE sku IN (SELECT sku FROM products_in_multiple_stores)
)
SELECT 
  brand,
  CORR(price, stock_quantity) AS correlation
FROM product_stock_data
GROUP BY brand;
```
* **Spanner Query:**
> [!NOTE]
> Like Query 2, Spanner uses Pearson correlation coefficient formula calculations due to the absence of the native `CORR()` function.
```sql
WITH products_in_multiple_stores AS (
  SELECT sku
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(s.store_id, p.sku)
  )
  GROUP BY sku
  HAVING COUNT(DISTINCT store_id) > 1
),
product_stock_data AS (
  SELECT 
    brand, 
    CAST(price AS FLOAT64) AS x, 
    CAST(stock_quantity AS FLOAT64) AS y
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(p.sku, p.brand, p.price, st.stock_quantity)
  )
  WHERE sku IN (SELECT sku FROM products_in_multiple_stores)
)
SELECT 
  brand,
  (COUNT(*) * SUM(x * y) - SUM(x) * SUM(y)) /
  SQRT((COUNT(*) * SUM(x * x) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(y * y) - SUM(y) * SUM(y))) AS correlation
FROM product_stock_data
GROUP BY brand;
```

---

### Query 10: Avg Unique Product SKUs per Store by State (Total Stock > 100)
* **Question:** Determine the average number of unique product SKUs per store, broken down by state, for stores with more than 100 products in stock.
* **BigQuery Query:**
```sql
WITH store_stock_totals AS (
  SELECT 
    store_id,
    store_name,
    store_state,
    COUNT(DISTINCT sku) AS unique_skus,
    SUM(stock_quantity) AS total_stock
  FROM GRAPH_TABLE(
    `dsg-vip-customer-demo.dsg_graph.customer_retail_graph`
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(s.store_id, s.name AS store_name, s.state AS store_state, p.sku, st.stock_quantity)
  )
  GROUP BY store_id, store_name, store_state
)
SELECT 
  store_state,
  AVG(unique_skus) AS avg_unique_skus_per_store,
  COUNT(store_id) AS store_count
FROM store_stock_totals
WHERE total_stock > 100
GROUP BY store_state;
```
* **Spanner Query:**
```sql
WITH store_stock_totals AS (
  SELECT 
    store_id,
    store_name,
    store_state,
    COUNT(DISTINCT sku) AS unique_skus,
    SUM(stock_quantity) AS total_stock
  FROM GRAPH_TABLE(
    customer_retail_graph
    MATCH (s:store)-[st:stocks]->(p:product)
    COLUMNS(s.store_id, s.name AS store_name, s.state AS store_state, p.sku, st.stock_quantity)
  )
  GROUP BY store_id, store_name, store_state
)
SELECT 
  store_state,
  AVG(unique_skus) AS avg_unique_skus_per_store,
  COUNT(store_id) AS store_count
FROM store_stock_totals
WHERE total_stock > 100
GROUP BY store_state;
```
