{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

select
  order_id,
  sku,
  cast(quantity as int64) as quantity,
  cast(price as numeric) as price
from {{ ref('raw_order_items') }}
