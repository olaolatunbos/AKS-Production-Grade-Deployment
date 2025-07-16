resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  address_space       = var.virtual_network_address_space
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  tags = {
    environment = var.deployment_environment
  }
}

resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
}
