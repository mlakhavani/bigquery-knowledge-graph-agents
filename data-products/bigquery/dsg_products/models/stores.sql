{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

select
  store_id,
  name,
  address,
  city,
  state,
  zip_code,
  phone_number
from {{ ref('raw_stores') }}
