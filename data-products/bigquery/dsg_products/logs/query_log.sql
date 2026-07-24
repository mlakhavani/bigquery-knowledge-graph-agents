-- created_at: 2026-06-17T21:25:00.988855+00:00
-- finished_at: 2026-06-17T21:25:03.572128+00:00
-- elapsed: 2.6s
-- outcome: success
-- dialect: bigquery
-- node_id: not available
-- query_id: QWFE4XxIup9GCOkbiGrjc4zIaoL
-- desc: execute adapter call
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "dsg_products", "target_name": "dev"} */

    select distinct schema_name from `dsg-vip-customer-demo`.INFORMATION_SCHEMA.SCHEMATA;
  ;
-- created_at: 2026-06-17T21:25:03.587168+00:00
-- finished_at: 2026-06-17T21:25:05.924271+00:00
-- elapsed: 2.3s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.stores
-- query_id: xAoklo5sqsTXTVDeDr1I7TBGqjM
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_products`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:25:03.586299+00:00
-- finished_at: 2026-06-17T21:25:05.938196+00:00
-- elapsed: 2.4s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.products
-- query_id: e3dxkc8i2ga6p0AJVQeVGsIVopK
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_products`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:25:03.593794+00:00
-- finished_at: 2026-06-17T21:25:06.198584+00:00
-- elapsed: 2.6s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.inventory
-- query_id: PbgzbOvo8aSi3rOZjXp5SjQEjlm
-- desc: get_relation > list_relations call
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM 
    `dsg-vip-customer-demo`.`dsg_products`.INFORMATION_SCHEMA.TABLES;
-- created_at: 2026-06-17T21:25:05.941792+00:00
-- finished_at: 2026-06-17T21:25:10.309632+00:00
-- elapsed: 4.4s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.products
-- query_id: E8Dz16S0iDx4Ldveo5vxTlgW6Y9
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_products.products", "profile_name": "dsg_products", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_products`.`products`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_products/products',
    
      table_format='iceberg'
    )
    as (
      

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
from `dsg-vip-customer-demo`.`dsg_products`.`raw_shoe_inventory`
    );
  ;
-- created_at: 2026-06-17T21:25:05.932691+00:00
-- finished_at: 2026-06-17T21:25:10.703982+00:00
-- elapsed: 4.8s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.stores
-- query_id: ypF4rMhEcAHzmlglRZz9MIgeC8V
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_products.stores", "profile_name": "dsg_products", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_products`.`stores`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_products/stores',
    
      table_format='iceberg'
    )
    as (
      

select
  store_id,
  name,
  address,
  city,
  state,
  zip_code,
  phone_number
from `dsg-vip-customer-demo`.`dsg_products`.`raw_stores`
    );
  ;
-- created_at: 2026-06-17T21:25:06.204898+00:00
-- finished_at: 2026-06-17T21:25:10.933456+00:00
-- elapsed: 4.7s
-- outcome: success
-- dialect: bigquery
-- node_id: model.dsg_products.inventory
-- query_id: exMnuvcEhHyAiLMmcA6Hr2TP0NH
-- desc: execute adapter call
/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.dsg_products.inventory", "profile_name": "dsg_products", "target_name": "dev"} */

  
    

    create or replace table `dsg-vip-customer-demo`.`dsg_products`.`inventory`
      
    
    

    with connection default
    OPTIONS(
      file_format='parquet',
    
      storage_uri='gs://dsg-vip-customer-demo-dsg-data/_dbt/dsg_products/inventory',
    
      table_format='iceberg'
    )
    as (
      

with unnested_products as (
  select
    sku,
    split(colorways, ',') as colors,
    split(sizes, ',') as sizes
  from `dsg-vip-customer-demo`.`dsg_products`.`raw_shoe_inventory`
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
  select store_id from `dsg-vip-customer-demo`.`dsg_products`.`raw_stores`
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
    );
  ;
