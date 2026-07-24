CREATE TABLE customers (
  customer_id STRING(36) NOT NULL,
  name STRING(MAX),
  email STRING(MAX),
  phone_number STRING(MAX),
  address STRING(MAX),
  city STRING(MAX),
  state STRING(MAX),
  zip_code INT64,
  date_joined TIMESTAMP,
) PRIMARY KEY (customer_id);

CREATE TABLE customer_health (
  customer_id STRING(36) NOT NULL,
  sync_date DATE NOT NULL,
  device_type STRING(MAX),
  steps_count INT64,
  calories_burned INT64,
  avg_heart_rate INT64,
  active_minutes INT64,
  sleep_hours NUMERIC,
) PRIMARY KEY (customer_id, sync_date);

CREATE TABLE orders (
  order_id STRING(36) NOT NULL,
  customer_id STRING(36) NOT NULL,
  store_id STRING(36) NOT NULL,
  order_date TIMESTAMP,
  total_amount NUMERIC,
) PRIMARY KEY (order_id);

CREATE TABLE order_items (
  order_id STRING(36) NOT NULL,
  sku STRING(36) NOT NULL,
  quantity INT64,
  price NUMERIC,
) PRIMARY KEY (order_id, sku);

CREATE TABLE products (
  sku STRING(36) NOT NULL,
  name STRING(MAX),
  brand STRING(MAX),
  gender STRING(MAX),
  colors ARRAY<STRING(MAX)>,
  sizes ARRAY<STRING(MAX)>,
  image_url STRING(MAX),
  description STRING(MAX),
  marketing_pdf_url STRING(MAX),
  price NUMERIC,
) PRIMARY KEY (sku);

CREATE TABLE stores (
  store_id STRING(36) NOT NULL,
  name STRING(MAX),
  address STRING(MAX),
  city STRING(MAX),
  state STRING(MAX),
  zip_code INT64,
  phone_number STRING(MAX),
) PRIMARY KEY (store_id);

CREATE TABLE inventory (
  sku STRING(36) NOT NULL,
  store_id STRING(36) NOT NULL,
  color STRING(MAX) NOT NULL,
  size STRING(MAX) NOT NULL,
  stock_quantity INT64,
  supply_warehouse STRING(MAX),
  last_updated_at TIMESTAMP,
) PRIMARY KEY (sku, store_id, color, size);

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
