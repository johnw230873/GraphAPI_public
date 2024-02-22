resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-${var.vnet_name}"
  location            = azurerm_resource_group.rgp1.location
  resource_group_name = azurerm_resource_group.rgp1.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.rgp1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.2.1.0/24"]
}




resource "azurerm_public_ip" "pip1" {
  name                = "${var.prefix}-${var.public_ip_name}"
  location            = azurerm_resource_group.rgp1.location
  resource_group_name = azurerm_resource_group.rgp1.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "ni1" {
  name                = "${var.prefix}-${var.network_interface_name}"
  location            = azurerm_resource_group.rgp1.location
  resource_group_name = azurerm_resource_group.rgp1.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

