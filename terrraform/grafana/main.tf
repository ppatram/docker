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
  use_lockfile   = "true"

}
}


data "local_file" "nginx_dash" {
  filename = "${path.module}/nginx.dashboard.json"
}

#output "nginx_dash" {
#  value = data.local_file.nginx_dash.content
#}




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
  folder      = grafana_folder.my_folder.uid
  config_json = data.local_file.nginx_dash.content
}

