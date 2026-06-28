terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

# Configuración del proveedor de AWS
provider "aws" {
  region = "us-east-1" # Cambia a la región donde están tus instancias EC2
}

# Configuración del proveedor de Datadog
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  # Configura la región de Datadog
  api_url = var.datadog_api_url
}
