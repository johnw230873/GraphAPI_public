resource "azurerm_resource_group" "rgp1" {
  name     = "${var.prefix}-${var.main_resourcegroup}"
  location = var.location
}



