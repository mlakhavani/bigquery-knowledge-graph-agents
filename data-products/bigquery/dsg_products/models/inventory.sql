{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

with unnested_products as (
  select
    sku,
    split(colorways, ',') as colors,
    split(sizes, ',') as sizes
  from {{ ref('raw_shoe_inventory') }}
),
exploded_products as (
  select
    sku,
    color,
    size
  from unnested_products,
  unnest(colors) as color,
  unnest(sizes) as size
),
stores as (
  select store_id from {{ ref('raw_stores') }}
),
store_product_combinations as (
  select
    p.sku,
    s.store_id,
    p.color,
    p.size
  from exploded_products p
  cross join stores s
)
select
  sku,
  store_id,
  color,
  size,
  cast(floor(rand() * 51) as int64) as stock_quantity,
  case 
    when substr(store_id, 4, 2) = 'PA' then 'WH-EAST-1'
    when substr(store_id, 4, 2) = 'NY' then 'WH-EAST-1'
    when substr(store_id, 4, 2) = 'FL' then 'WH-EAST-1'
    when substr(store_id, 4, 2) = 'TX' then 'WH-MIDWEST-1'
    else 'WH-WEST-2'
  end as supply_warehouse,
  current_timestamp() as last_updated_at
from store_product_combinations
