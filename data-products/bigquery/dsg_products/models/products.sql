{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

select
  sku,
  name,
  brand,
  gender,
  split(colorways, ',') as colors,
  split(sizes, ',') as sizes,
  image_url,
  description,
  marketing_pdf_url,
  cast(price as numeric) as price
from {{ ref('raw_shoe_inventory') }}
