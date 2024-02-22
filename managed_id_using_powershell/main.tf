################################## Data sources #######################################
data "azurerm_client_config" "current" {} #retrive the current client id, tenant id of the provider etc

################################## locals #######################################
locals {
  aadTenantId     = data.azurerm_client_config.current.tenant_id
  applicationId   = data.azurerm_client_config.current.client_id
  DisplayNameOfMI = "testapp03"
  clientSecret    = var.clientSecret

}

################################## variables #######################################
variable "clientSecret" {
  default   = ""
  sensitive = true
}


######################################## main ############################################
# Create a resource group in Azure
resource "azurerm_resource_group" "main" {
  name     = "fzessrepdrgp002" # Name of the resource group
  location = "Australia East"  # Location where the resource group will be created
}

# Create a user-assigned managed identity in Azure
resource "azurerm_user_assigned_identity" "azuai1" {
  name                = local.DisplayNameOfMI                # Name of the user-assigned identity
  location            = azurerm_resource_group.main.location # Location will be the same as the resource group
  resource_group_name = azurerm_resource_group.main.name     # The resource group in which to create the identity
}

resource "time_sleep" "allow_time_to_sync" {
  depends_on      = [azurerm_user_assigned_identity.azuai1]
  create_duration = "30s"
}

resource "null_resource" "allow_time_to_sync" {
  triggers = {
    triggderid = time_sleep.allow_time_to_sync.id
  }
  provisioner "local-exec" {
    command = "${path.module}/scripts/graphapi.ps1 -applicationId ${local.applicationId} -clientSecret ${local.clientSecret} -aadTenantId ${local.aadTenantId} -DisplayNameOfMI ${local.DisplayNameOfMI}"

    interpreter = ["pwsh", "-c"]
  }
}


