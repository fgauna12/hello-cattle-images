resource "azurerm_resource_group" "resource_group" {
  name     = "rg-chia-${var.environment_name}"
  location = "eastus"

  tags = {
    customer = "Internal"
    owner    = "facundo@boxboat.com"
  }
}