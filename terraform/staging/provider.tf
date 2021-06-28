terraform {
  required_providers {
    azurerm = {
      version = "~>2.65"
    }
  }

  backend "azurerm" {
    storage_account_name = "stterraformhellocattle01"
    container_name       = "staging"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}