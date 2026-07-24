# BigQuery Knowledge Graph Agents

A production-grade collection of **Google Cloud BigQuery Conversational Data & Knowledge Graph Agents** designed for retail customer insights, store financial analytics, and graph analytics. Built with BigQuery Agents Hub, Vertex AI, Google Cloud Spanner Graph, and Terraform.

---

## 🚀 Overview

This repository contains two core BigQuery agents:

1. **DSG Enhanced VIP Customer Agent**:
   - Analyzes VIP customer profiles, purchase history, loyalty metrics, and endurance activity.
   - Leverages graph definitions for customer relationship mapping.
2. **DSG Financial Agent**:
   - Processes store-level financial metrics, inventory status, and sales performance.
   - Enables natural language queries over BigQuery data without manual SQL work.

---

## 📁 Repository Structure

```
├── agents/
│   ├── dsg_financial_agent/       # Financial & inventory agent configuration
│   ├── vip_customer_ca_agent/     # VIP customer profile agent
│   └── vip_customer_ca_graph_agent/ # Customer graph relationship agent
├── data-products/                # BigQuery schemas & data product definitions
├── terraform/                     # Cloud infrastructure automation
├── dsg_demo_script.md             # Demo script & sample queries
└── graph_definition_and_queries.md # Graph analytics documentation
```

---

## 🛠️ Prerequisites & Setup

- **Google Cloud Platform** project with BigQuery & Vertex AI enabled.
- **Terraform** v1.5+ for infrastructure deployment.
- **Python** 3.10+ for local helper scripts.

### Deploying Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

---

## 📄 License

Internal / Proprietary.
