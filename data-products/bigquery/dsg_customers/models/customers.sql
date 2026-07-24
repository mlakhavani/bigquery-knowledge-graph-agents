{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

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
from {{ ref('raw_customers') }}
