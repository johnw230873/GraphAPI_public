
# Get the well-known application IDs in Azure Active Directory
data "azuread_application_published_app_ids" "well_known" {}

# Get the service principal for Microsoft Graph
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"] # Client ID of Microsoft Graph
}


# Create an Azure Active Directory application
resource "azuread_application" "example" {
  display_name = "testapp01" # Name of the Azure AD application
}

# Create a service principal for the Azure AD application
resource "azuread_service_principal" "example" {
  client_id = azuread_application.example.client_id # Application ID of the Azure AD application
}


# Grant API access to service principal fzgenrlpdlog001uai001
resource "azuread_application_api_access" "example_msgraph2" {
  application_id = azuread_application.example.id                                                 # Application ID of the service principal
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"] # Client ID of Microsoft Graph

  # Assign roles to the service principal 
  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["Mail.ReadBasic"], # Role ID for basic mail read access
    data.azuread_service_principal.msgraph.app_role_ids["Mail.Send"],      # Role ID for mail send access
  ]
}

output "AppReg_Objectid" {
  value = azuread_application.example.id
}
