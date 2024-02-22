# Terraform configuration
terraform {
  # Terraform Cloud setup
  cloud {
    organization = "<your TC Org>" # Terraform Cloud organization

    workspaces {
      name = "Managed-Indentities-AZURERM" # Workspace name
    }
  }

  # Required providers
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.88.0" # Azurerm provider version
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0" # Azuread provider version
    }
  }
}
