/*
* Virtual Network
*/
module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_prefixes     = ["10.0.0.0/24", "10.0.1.0/24"]
  subnet_names        = ["GatewaySubnet", "app"]
  vnet_name = "vnet-chia-nonprod"

  depends_on = [
    azurerm_resource_group.resource_group
  ]
}

/*
* Public IP for the VPN Gateway
*/
resource "azurerm_public_ip" "pip" {
  name                = "pip-chia-nonprod"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.resource_group.name

  allocation_method = "Dynamic"
}

/*
* VPN Gateway
*/
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "vpng-chia-nonprod"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.resource_group.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  

  ip_configuration {
    name                          = "vnet-gateway-config"
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.network.vnet_subnets[0]
  }

  vpn_client_configuration {
    address_space = ["10.1.0.0/24"]

    aad_issuer = "https://sts.windows.net/${var.tenant_id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4" # azure public cloud
    aad_tenant = "https://login.microsoftonline.com/${var.tenant_id}/"

    vpn_client_protocols = ["OpenVPN"]
  }
}