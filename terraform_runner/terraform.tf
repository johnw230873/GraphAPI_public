terraform {
  # Terraform Cloud setup
  cloud {
    organization = "<your TC Org>" # Terraform Cloud organization

    workspaces {
      name = "terraform-runner"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.88.0"
    }
  }
}
