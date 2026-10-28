terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Remote state stored in Azure Blob Storage with native blob lease locking.
  # Initialize with: terraform init -backend-config=backend.hcl
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Workload    = var.cluster_name
    ManagedBy   = "terraform"
  }
}
