{{ config(
    materialized='view',
    post_hook=[
        "DROP PROPERTY GRAPH IF EXISTS `{{ var('project_id') }}.{{ this.schema }}.customer_retail_graph`",
        """
        CREATE OR REPLACE PROPERTY GRAPH `{{ var('project_id') }}.dsg_graph.customer_retail_graph`
        NODE TABLES (
          `{{ var('project_id') }}.{{ this.schema }}.customers` AS customer
            KEY (customer_id)
            LABEL customer
            PROPERTIES (customer_id, name, email, phone_number, address, city, state, zip_code, date_joined),
          `{{ var('project_id') }}.{{ this.schema }}.orders` AS sales_order
            KEY (order_id)
            LABEL sales_order
            PROPERTIES (order_id, customer_id, store_id, order_date, total_amount),
          `{{ var('project_id') }}.dsg_products.products` AS product
            KEY (sku)
            LABEL product
            PROPERTIES (sku, name, brand, gender, colors, sizes, image_url, description, price, marketing_pdf_url),
          `{{ var('project_id') }}.dsg_products.stores` AS store
            KEY (store_id)
            LABEL store
            PROPERTIES (store_id, name, address, city, state, zip_code, phone_number),
          `{{ var('project_id') }}.{{ this.schema }}.customer_health` AS customer_health
            KEY (customer_id, sync_date)
            LABEL customer_health
            PROPERTIES (customer_id, sync_date, device_type, steps_count, calories_burned, avg_heart_rate, active_minutes, sleep_hours)
        )
        EDGE TABLES (
          `{{ var('project_id') }}.{{ this.schema }}.orders` AS order_placed_by
            KEY (order_id)
            SOURCE KEY (order_id) REFERENCES sales_order(order_id)
            DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
            LABEL placed_by,
          `{{ var('project_id') }}.{{ this.schema }}.orders` AS order_in_store
            KEY (order_id)
            SOURCE KEY (order_id) REFERENCES sales_order(order_id)
            DESTINATION KEY (store_id) REFERENCES store(store_id)
            LABEL in_store,
          `{{ var('project_id') }}.{{ this.schema }}.order_items` AS order_purchased_product
            KEY (order_id, sku)
            SOURCE KEY (order_id) REFERENCES sales_order(order_id)
            DESTINATION KEY (sku) REFERENCES product(sku)
            LABEL purchased
            PROPERTIES (quantity, price),
          `{{ var('project_id') }}.{{ this.schema }}.customer_health` AS health_for_customer
            KEY (customer_id, sync_date)
            SOURCE KEY (customer_id, sync_date) REFERENCES customer_health(customer_id, sync_date)
            DESTINATION KEY (customer_id) REFERENCES customer(customer_id)
            LABEL health_for,
          `{{ var('project_id') }}.dsg_products.inventory` AS store_stocks_product
            KEY (sku, store_id, color, size)
            SOURCE KEY (store_id) REFERENCES store(store_id)
            DESTINATION KEY (sku) REFERENCES product(sku)
            LABEL stocks
            PROPERTIES (color, size, stock_quantity, supply_warehouse, last_updated_at)
        )
        """
    ]
) }}

-- Dummy query to create the DAG dependency on the customer tables
SELECT 
  1 AS dummy
FROM {{ ref('customers') }}
CROSS JOIN {{ ref('orders') }}
CROSS JOIN {{ ref('order_items') }}
CROSS JOIN {{ ref('customer_health') }}
LIMIT 1
