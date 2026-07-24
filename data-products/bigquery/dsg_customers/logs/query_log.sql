-- created_at: 2026-06-17T21:28:46.792663+00:00
-- finished_at: 2026-06-17T21:28:48.750883+00:00
-- elapsed: 2.0s
-- outcome: success
-- dialect: bigquery
-- node_id: not available
-- query_id: cE2dSzMY0gfdTUc3XrgLrE5TRlC
-- desc: execute adapter call
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "dsg_customers", "target_name": "dev"} */

    select distinct schema_name from `dsg-vip-customer-demo`.INFORMATION_SCHEMA.SCHEMATA;
  ;
-- created_at: 2026-06-17T21:28:48.768360+00:00
-- finished_at: 2026-06-17T21:28:50.735450+00:00
-- elapsed: 2.0s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customers
-- query_id: 8grXiYpYAzogK1arGR6G7vTOktr
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_customers`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:28:48.766604+00:00
-- finished_at: 2026-06-17T21:28:50.930721+00:00
-- elapsed: 2.2s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.orders
-- query_id: T9foyZQfahUVPTSyAYyGy13SESa
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_customers`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:28:48.767543+00:00
-- finished_at: 2026-06-17T21:28:51.051034+00:00
-- elapsed: 2.3s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customer_health
-- query_id: gbhWvdTXR0XJWni1KRZTFeX78Sb
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_customers`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:28:48.765520+00:00
-- finished_at: 2026-06-17T21:28:51.241010+00:00
-- elapsed: 2.5s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.order_items
-- query_id: grXxm3aNxiFxBMlJ68HZ8twPLKL
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_customers`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:28:50.928961+00:00
-- finished_at: 2026-06-17T21:28:54.656059+00:00
-- elapsed: 3.7s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customers
-- query_id: 1qln8Tppht6OFnHV9oycVsNKawo
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.customers", "profile_name": "dsg_customers", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_customers`.`customers`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_customers/customers',
    
      table_format='iceberg'
    )
    as (
      

select
  customer_id,
  name,
  email,
  phone_number,
  address,
  city,
  state,
  zip_code,
  cast(date_joined as timestamp) as date_joined
from `dsg-vip-customer-demo`.`dsg_customers`.`raw_customers`
    );
  ;
-- created_at: 2026-06-17T21:28:51.057910+00:00
-- finished_at: 2026-06-17T21:28:55.136580+00:00
-- elapsed: 4.1s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customer_health
-- query_id: EdQ6H5lg9EbkC6qaRPXXi6SIsh0
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.customer_health", "profile_name": "dsg_customers", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_customers`.`customer_health`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_customers/customer_health',
    
      table_format='iceberg'
    )
    as (
      

select
  customer_id,
  cast(sync_date as date) as sync_date,
  device_type,
  cast(steps_count as int64) as steps_count,
  cast(calories_burned as int64) as calories_burned,
  cast(avg_heart_rate as int64) as avg_heart_rate,
  cast(active_minutes as int64) as active_minutes,
  cast(sleep_hours as numeric) as sleep_hours
from `dsg-vip-customer-demo`.`dsg_customers`.`raw_customer_health`
    );
  ;
-- created_at: 2026-06-17T21:28:51.247404+00:00
-- finished_at: 2026-06-17T21:28:55.231102+00:00
-- elapsed: 4.0s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.order_items
-- query_id: JscpDfKWavcNSdPeH5ont6gjYkC
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.order_items", "profile_name": "dsg_customers", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_customers`.`order_items`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_customers/order_items',
    
      table_format='iceberg'
    )
    as (
      

select
  order_id,
  sku,
  cast(quantity as int64) as quantity,
  cast(price as numeric) as price
from `dsg-vip-customer-demo`.`dsg_customers`.`raw_order_items`
    );
  ;
-- created_at: 2026-06-17T21:28:50.934262+00:00
-- finished_at: 2026-06-17T21:28:55.557330+00:00
-- elapsed: 4.6s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.orders
-- query_id: oZ1JvpHDx8loEJmZOF3EvY1shp1
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.orders", "profile_name": "dsg_customers", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_customers`.`orders`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_customers/orders',
    
      table_format='iceberg'
    )
    as (
      

select
  order_id,
  customer_id,
  store_id,
  cast(order_date as timestamp) as order_date,
  cast(total_amount as numeric) as total_amount
from `dsg-vip-customer-demo`.`dsg_customers`.`raw_orders`
    );
  ;
-- created_at: 2026-06-17T21:28:55.565781+00:00
-- finished_at: 2026-06-17T21:28:57.403882+00:00
-- elapsed: 1.8s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customer_retail_graph_trigger
-- query_id: Qo2yZDraVzlkHQNvMxnYhrEn7mq
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.customer_retail_graph_trigger", "profile_name": "dsg_customers", "target_name": "dev"} */


  create or replace view `dsg-vip-customer-demo`.`dsg_customers`.`customer_retail_graph_trigger`
  OPTIONS()
  as 

-- Dummy query to create the DAG dependency on the customer tables
SELECT 
  1 AS dummy
FROM `dsg-vip-customer-demo`.`dsg_customers`.`customers`
CROSS JOIN `dsg-vip-customer-demo`.`dsg_customers`.`orders`
CROSS JOIN `dsg-vip-customer-demo`.`dsg_customers`.`order_items`
CROSS JOIN `dsg-vip-customer-demo`.`dsg_customers`.`customer_health`
LIMIT 1;

;
-- created_at: 2026-06-17T21:28:57.405629+00:00
-- finished_at: 2026-06-17T21:28:57.947237+00:00
-- elapsed: 541ms
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customer_retail_graph_trigger
-- query_id: MeRowjJis5D2VLBxoPkV9bKyR52
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.customer_retail_graph_trigger", "profile_name": "dsg_customers", "target_name": "dev"} */

        DROP PROPERTY GRAPH IF EXISTS `dsg-vip-customer-demo.dsg_customers.customer_retail_graph`
      ;
-- created_at: 2026-06-17T21:28:57.948380+00:00
-- finished_at: 2026-06-17T21:28:58.921194+00:00
-- elapsed: 972ms
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_customers.customer_retail_graph_trigger
-- query_id: XGZZsZ3DH5y9eTtqv712Ka2h0Ho
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_customers.customer_retail_graph_trigger", "profile_name": "dsg_customers", "target_name": "dev"} */

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
        )
      ;
