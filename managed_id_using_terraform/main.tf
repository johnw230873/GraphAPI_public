# Get the well-known application IDs in Azure Active Directory
data "azuread_application_published_app_ids" "well_known" {}

# Get the service principal for Microsoft Graph
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"] # Client ID of Microsoft Graph
}


# Create a resource group in Azure
resource "azurerm_resource_group" "example" {
  name     = "fzessrepdrgp001" # Name of the resource group
  location = "Australia East"  # Location where the resource group will be created
}

# Create a user-assigned managed identity in Azure
resource "azurerm_user_assigned_identity" "example" {
  name                = "testapp02"                             # Name of the user-assigned identity
  location            = azurerm_resource_group.example.location # Location will be the same as the resource group
  resource_group_name = azurerm_resource_group.example.name     # The resource group in which to create the identity
}


# Grant API access to managed identity fzgenrlpdlog001uai001
resource "azuread_application_api_access" "example_msgraph2" {
  depends_on = [azurerm_user_assigned_identity.example]

  application_id = "/applications/${azurerm_user_assigned_identity.example.principal_id}"         # Application ID of the user-assigned identity
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"] # Client ID of Microsoft Graph

  # Assign roles to the managed identity 
  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["Mail.ReadBasic"], # Role ID for basic mail read access
    data.azuread_service_principal.msgraph.app_role_ids["Mail.Send"],      # Role ID for mail send access
  ]
}

output "EA_Objectid" {
  value = "/applications/${azurerm_user_assigned_identity.example.principal_id}"
}

