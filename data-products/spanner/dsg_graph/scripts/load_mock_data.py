import os
import sys
from google.cloud import bigquery
from google.cloud import spanner
from decimal import Decimal

def main():
    project_id = os.environ.get("PROJECT_ID", "dsg-vip-customer-demo")
    instance_id = os.environ.get("SPANNER_INSTANCE", "dsg-spanner")

    print(f"Project ID: {project_id}")
    print(f"Spanner Instance: {instance_id}")

    bq_client = bigquery.Client(project=project_id)
    spanner_client = spanner.Client(project=project_id)
    spanner_instance = spanner_client.instance(instance_id)

    sync_graph_db(bq_client, spanner_instance)

def sync_graph_db(bq_client, spanner_instance):
    db_id = "dsg_graph"
    print(f"Syncing Spanner database: {db_id}")
    database = spanner_instance.database(db_id)

    # Tables to sync: (bq_dataset_name, table_name, columns)
    tables = [
        ("dsg_customers", "customers", ["customer_id", "name", "email", "phone_number", "address", "city", "state", "zip_code", "date_joined"]),
        ("dsg_customers", "customer_health", ["customer_id", "sync_date", "device_type", "steps_count", "calories_burned", "avg_heart_rate", "active_minutes", "sleep_hours"]),
        ("dsg_customers", "orders", ["order_id", "customer_id", "store_id", "order_date", "total_amount"]),
        ("dsg_customers", "order_items", ["order_id", "sku", "quantity", "price"]),
        ("dsg_products", "products", ["sku", "name", "brand", "gender", "colors", "sizes", "image_url", "description", "marketing_pdf_url", "price"]),
        ("dsg_products", "stores", ["store_id", "name", "address", "city", "state", "zip_code", "phone_number"]),
        ("dsg_products", "inventory", ["sku", "store_id", "color", "size", "stock_quantity", "supply_warehouse", "last_updated_at"])
    ]

    for dataset_name, table_name, columns in tables:
        print(f"  Table: {table_name}")
        # Read from BigQuery
        query = f"SELECT {', '.join(columns)} FROM `{dataset_name}.{table_name}`"
        query_job = bq_client.query(query)
        rows = list(query_job.result())
        print(f"    Read {len(rows)} rows from BigQuery")

        # Convert rows for Spanner
        spanner_data = []
        for row in rows:
            values = []
            for col in columns:
                val = row[col]
                # Spanner expects decimal.Decimal for NUMERIC
                if val is not None and col in ["sleep_hours", "total_amount", "price"]:
                    val = Decimal(str(val))
                elif col in ["colors", "sizes"] and val is not None:
                    val = list(val)
                values.append(val)
            spanner_data.append(values)

        # Write to Spanner using a batch insert/update (upsert)
        if spanner_data:
            chunk_size = 500
            for i in range(0, len(spanner_data), chunk_size):
                chunk = spanner_data[i:i+chunk_size]
                with database.batch() as batch:
                    batch.insert_or_update(
                        table=table_name,
                        columns=columns,
                        values=chunk
                     )
            print(f"    Wrote {len(spanner_data)} rows to Spanner")

if __name__ == "__main__":
    main()
