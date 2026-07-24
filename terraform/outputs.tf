output "project_id" {
  value       = var.project_id
  description = "The ID of the GCP project"
}

output "project_number" {
  value       = data.google_project.project.number
  description = "The number of the GCP project"
}

output "bigquery_datasets" {
  value = [
    google_bigquery_dataset.dsg_products.dataset_id,
    google_bigquery_dataset.dsg_customers.dataset_id,
  ]
  description = "The created BigQuery datasets"
}

output "spanner_instance" {
  value       = google_spanner_instance.spanner_instance.name
  description = "The name of the created Spanner instance"
}

output "spanner_databases" {
  value = [
    google_spanner_database.dsg_graph.name,
  ]
  description = "The created Spanner databases"
}

output "gcs_bucket_name" {
  value       = google_storage_bucket.dsg_data.name
  description = "The name of the GCS bucket created for DSG data"
}

output "gcs_connection_id" {
  value       = google_bigquery_connection.gcs_connection.id
  description = "The ID of the BigQuery GCS connection"
}

output "gcs_connection_service_account" {
  value       = google_bigquery_connection.gcs_connection.cloud_resource[0].service_account_id
  description = "The service account used by the BigQuery GCS connection"
}

