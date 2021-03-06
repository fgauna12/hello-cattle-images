/*
* Virtual Machine
*/
module "chia_farmer" {
  source = "../modules/chia_farmer"

  shared_image_gallery_resource_group_name = "rg-packer-001"
  resource_group_name                      = azurerm_resource_group.resource_group.name
  prefix                                   = "chia"
  subnet_id                                = module.network.vnet_subnets[1]
  location                                 = "eastus"
  image_version                            = "1.0.2"
  image_name                               = "chia"
  shared_image_gallery_name                = "BoxBoat"
  ssh_public_key_name                      = "ssh-facundo-windows"
  ssh_public_key_resource_group            = "rg-facundo-001"

  depends_on = [
    module.network
  ]
}