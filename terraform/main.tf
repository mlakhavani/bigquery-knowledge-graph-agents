data "google_project" "project" {
  project_id = var.project_id
}

# Define the APIs we want to enable in the project
locals {

  services = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "bigquery.googleapis.com",
    "spanner.googleapis.com",
    "storage.googleapis.com",
    "bigqueryconnection.googleapis.com",
  ]
}

resource "google_project_service" "enabled_services" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key

  disable_on_destroy = false
}


resource "google_project_service" "data_analytics_api" {
  project = data.google_project.project.project_id
  service = "geminidataanalytics.googleapis.com"

  disable_on_destroy = false
}

# BigQuery Datasets
resource "google_bigquery_dataset" "dsg_products" {
  project                    = var.project_id
  dataset_id                 = "dsg_products"
  location                   = var.region
  delete_contents_on_destroy = true

  depends_on = [google_project_service.enabled_services]
}

resource "google_bigquery_dataset" "dsg_customers" {
  project                    = var.project_id
  dataset_id                 = "dsg_customers"
  location                   = var.region
  delete_contents_on_destroy = true

  depends_on = [google_project_service.enabled_services]
}

resource "google_bigquery_dataset" "dsg_graph" {
  project                    = var.project_id
  dataset_id                 = "dsg_graph"
  location                   = var.region
  delete_contents_on_destroy = true

  depends_on = [google_project_service.enabled_services]
}

# Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  provider     = google-beta
  project      = var.project_id
  name         = var.spanner_instance_name
  config       = var.spanner_config
  display_name = var.spanner_instance_display_name
  edition      = "ENTERPRISE"
  
  # Minimal size for development
  processing_units = var.spanner_processing_units

  default_backup_schedule_type = "NONE"

  depends_on = [google_project_service.enabled_services]
}

# Spanner Databases (the user referred to these as datasets)

resource "google_spanner_database" "dsg_products" {
  project             = var.project_id
  instance            = google_spanner_instance.spanner_instance.name
  name                = "dsg_products"
  deletion_protection = false

  depends_on = [google_spanner_instance.spanner_instance]
}

resource "google_spanner_database" "dsg_customers" {
  project             = var.project_id
  instance            = google_spanner_instance.spanner_instance.name
  name                = "dsg_customers"
  deletion_protection = false

  depends_on = [google_spanner_instance.spanner_instance]
}

resource "google_spanner_database" "dsg_graph" {
  project             = var.project_id
  instance            = google_spanner_instance.spanner_instance.name
  name                = "dsg_graph"
  deletion_protection = false

  ddl = [for statement in split(";", file("${path.module}/../data-products/spanner/dsg_graph/ddl/schema.sql")) : trimspace(statement) if trimspace(statement) != ""]

  depends_on = [google_spanner_instance.spanner_instance]
}


# Cloud Storage Bucket for DSG Data (BigQuery Iceberg Tables)
resource "google_storage_bucket" "dsg_data" {
  project                     = var.project_id
  name                        = "${var.project_id}-dsg-data"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true # for dev/mock environment

  depends_on = [google_project_service.enabled_services]
}

# BigQuery Cloud Resource Connection for GCS
resource "google_bigquery_connection" "gcs_connection" {
  project       = var.project_id
  connection_id = "gcs_connection"
  location      = var.region
  friendly_name = "GCS Connection for Iceberg tables"
  cloud_resource {}

  depends_on = [google_project_service.enabled_services]
}

# IAM Role Bindings for BigQuery Connection on GCS Bucket
resource "google_storage_bucket_iam_member" "gcs_connection_storage_user" {
  bucket = google_storage_bucket.dsg_data.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_bigquery_connection.gcs_connection.cloud_resource[0].service_account_id}"
}

resource "google_storage_bucket_iam_member" "gcs_connection_bucket_reader" {
  bucket = google_storage_bucket.dsg_data.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_bigquery_connection.gcs_connection.cloud_resource[0].service_account_id}"
}


