{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

select
  order_id,
  customer_id,
  store_id,
  cast(order_date as timestamp) as order_date,
  cast(total_amount as numeric) as total_amount
from {{ ref('raw_orders') }}
