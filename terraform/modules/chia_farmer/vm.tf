locals {
  admin_user = "chia-admin"
}

data "azurerm_shared_image_version" "shared_image_gallery_version" {
  name                = var.image_version
  image_name          = var.image_name
  gallery_name        = var.shared_image_gallery_name
  resource_group_name = var.shared_image_gallery_resource_group_name
}

data "azurerm_ssh_public_key" "ssh_public_key" {
  name                = var.ssh_public_key_name
  resource_group_name = var.ssh_public_key_resource_group
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "${var.prefix}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = local.admin_user
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  source_image_id = data.azurerm_shared_image_version.shared_image_gallery_version.id

  admin_ssh_key {
    username   = local.admin_user
    public_key = data.ssh_public_key.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}