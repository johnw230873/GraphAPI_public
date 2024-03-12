
terraform {
  cloud {
    organization = "<your TC Org>" # Terraform Cloud organization

    workspaces {
      name = "get-env"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.88.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
  }
}

provider "azurerm" {
  features {}
}
provider "azuread" {
  # Configuration options
}
resource "azurerm_resource_group" "example" {
  name     = "fzessrepdrgp001"
  location = "Australia East"
}

