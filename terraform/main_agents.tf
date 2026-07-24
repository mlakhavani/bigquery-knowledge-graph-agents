# The original vip_customer_agent is kept as-is from v1 deployment.

resource "null_resource" "create_vip_customer_graph_agent" {
  triggers = {
    yaml_hash = filebase64sha256("${path.module}/../agents/vip_customer_ca_graph_agent/agent.yaml")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../agents/vip_customer_ca_graph_agent && ../../.venv/bin/python create_agent.py"
    environment = {
      PROJECT_ID = data.google_project.project.project_id
    }
  }

  depends_on = [
    google_project_service.data_analytics_api,
    terraform_data.dbt_deploy_customers,
    terraform_data.dbt_deploy_retail_data_manager,
    terraform_data.spanner_seed_graph,
    google_bigquery_dataset_iam_member.gda_dsg_graph_viewer,
    google_bigquery_dataset_iam_member.gda_dsg_customers_viewer,
    google_bigquery_dataset_iam_member.gda_dsg_products_viewer
  ]
}


resource "null_resource" "create_financial_agent" {
  triggers = {
    yaml_hash = filebase64sha256("${path.module}/../agents/dsg_financial_agent/agent.yaml")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../agents/dsg_financial_agent && ../../.venv/bin/python create_agent.py"
    environment = {
      PROJECT_ID = data.google_project.project.project_id
    }
  }

  depends_on = [
    google_project_service.data_analytics_api,
    terraform_data.dbt_deploy_customers,
    terraform_data.dbt_deploy_retail_data_manager,
    google_bigquery_dataset_iam_member.gda_dsg_customers_viewer,
    google_bigquery_dataset_iam_member.gda_dsg_products_viewer
  ]
}



resource "terraform_data" "dbt_deploy_customers" {
  triggers_replace = {
    hash = sha256(join("", concat(
      [for f in fileset("${path.module}/../data-products/bigquery/dsg_customers/models", "*.sql") : filesha256("${path.module}/../data-products/bigquery/dsg_customers/models/${f}")],
      [for f in fileset("${path.module}/../data-products/bigquery/dsg_customers/seeds", "*.csv") : filesha256("${path.module}/../data-products/bigquery/dsg_customers/seeds/${f}")]
    )))
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../data-products/bigquery/dsg_customers && ../../../.venv/bin/dbt seed && ../../../.venv/bin/dbt run"
  }
}

resource "terraform_data" "dbt_deploy_retail_data_manager" {
  triggers_replace = {
    hash = sha256(join("", concat(
      [for f in fileset("${path.module}/../data-products/bigquery/dsg_products/models", "*.sql") : filesha256("${path.module}/../data-products/bigquery/dsg_products/models/${f}")],
      [for f in fileset("${path.module}/../data-products/bigquery/dsg_products/seeds", "*.csv") : filesha256("${path.module}/../data-products/bigquery/dsg_products/seeds/${f}")]
    )))
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../data-products/bigquery/dsg_products && ../../../.venv/bin/dbt seed && ../../../.venv/bin/dbt run"
  }
}




resource "terraform_data" "spanner_seed_graph" {
  triggers_replace = {
    script_hash = filesha256("${path.module}/../data-products/spanner/dsg_graph/scripts/load_mock_data.py")
    ddl_hash    = filesha256("${path.module}/../data-products/spanner/dsg_graph/ddl/schema.sql")
    bq_hash     = terraform_data.dbt_deploy_customers.output
  }

  provisioner "local-exec" {
    command = "${path.module}/../.venv/bin/python ${path.module}/../data-products/spanner/dsg_graph/scripts/load_mock_data.py"
    environment = {
      PROJECT_ID       = data.google_project.project.project_id
      SPANNER_INSTANCE = google_spanner_instance.spanner_instance.name
    }
  }

  depends_on = [
    google_spanner_database.dsg_graph,
    terraform_data.dbt_deploy_customers,
    terraform_data.dbt_deploy_retail_data_manager
  ]
}

resource "google_project_service_identity" "gda_service_identity" {
  provider = google-beta
  project  = data.google_project.project.project_id
  service  = "geminidataanalytics.googleapis.com"
}

resource "google_bigquery_dataset_iam_member" "gda_dsg_graph_viewer" {
  project    = data.google_project.project.project_id
  dataset_id = google_bigquery_dataset.dsg_graph.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_project_service_identity.gda_service_identity.email}"
}

resource "google_bigquery_dataset_iam_member" "gda_dsg_customers_viewer" {
  project    = data.google_project.project.project_id
  dataset_id = google_bigquery_dataset.dsg_customers.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_project_service_identity.gda_service_identity.email}"
}

resource "google_bigquery_dataset_iam_member" "gda_dsg_products_viewer" {
  project    = data.google_project.project.project_id
  dataset_id = google_bigquery_dataset.dsg_products.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_project_service_identity.gda_service_identity.email}"
}