terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.0.0" # Use the latest major version available
    }
  }
backend "s3" {
  bucket         = "tfstate-iek"
  key            = "grafana/tf-state" # <-- Unique Key
  dynamodb_table = "tf-lock"
}




}



provider "grafana" {
  url  = "http://kubernetes.hakerie.fyi:3000"           # The URL of your local Grafana server
  auth = var.GRAFANA_API_TOKEN
}

# Create a Folder
resource "grafana_folder" "my_folder" {
  title = "Infrastructure Metrics"
}

# Create a Prometheus Data Source
resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "Local-Prometheus"
  url  = "http://localhost:9090" # URL where your Prometheus instance is running
}

# Create a Dashboard inside the folder
resource "grafana_dashboard" "my_dashboard" {
  folder = grafana_folder.my_folder.uid
  config_json = jsonencode({
    title = "Local Server Overview"
    uid   = "local-srv-overview"
    panels = [] # Paste your exported panel JSON configuration arrays here
  })
}

