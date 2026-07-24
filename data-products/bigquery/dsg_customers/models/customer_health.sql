{{ config(
    materialized='table',
    catalog='gcs_iceberg'
) }}

select
  customer_id,
  cast(sync_date as date) as sync_date,
  device_type,
  cast(steps_count as int64) as steps_count,
  cast(calories_burned as int64) as calories_burned,
  cast(avg_heart_rate as int64) as avg_heart_rate,
  cast(active_minutes as int64) as active_minutes,
  cast(sleep_hours as numeric) as sleep_hours
from {{ ref('raw_customer_health') }}
