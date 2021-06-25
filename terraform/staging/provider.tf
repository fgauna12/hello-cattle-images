terraform {
  required_providers {
    azurerm = {
      version = "~>2.65"
    }
  }
}

provider "azurerm" {
  features {}
}