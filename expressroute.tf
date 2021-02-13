
locals {
  lz = jsondecode(file("lz_input.json"))

}

# Create a resource group
resource "azurerm_resource_group" "lz_rg" {
  for_each =  { for k in local.lz.ResourceGroup : k.Env => k}
  name = each.value.Name
  location = each.value.Region
  tags     = merge(local.lz.Tags[0],{
  Resourcetype="ResourceGroup"
  })
}


# Creates Virtual Networks 
resource "azurerm_virtual_network" "lz_vnet" {
  for_each =  { for k in local.lz.Vnet : k.Vnet => k}
  name                = each.value.Vnet_Name
  location            = each.value.Region
  resource_group_name = each.value.Resourcegroup_Name
  address_space       = [each.value.Addres_Space]
  tags     = merge(local.lz.Tags[0],{
    Resourcetype="VirtualNetwork"
  })
  }

    
# Creates Subnets 
resource "azurerm_subnet" "lz_subnet" {
  for_each =  { for k in local.lz.Subnet : k.Subnet_Name => k}
  name                 = each.value.Subnet_Name
  resource_group_name  = each.value.Resourcegroup_Name
  virtual_network_name = each.value.Vnet_Name
  address_prefix       = each.value.Address_Space
  depends_on = [azurerm_virtual_network.lz_vnet]
}


resource "azurerm_express_route_circuit" "lz_connect" {
  for_each =  { for k in local.lz.Expressroute : k.Name => k}
  name                  = each.value.Name
  resource_group_name   = each.value.Resource_group_name
  location              = each.value.Region
  service_provider_name = each.value.Service_provider_name
  peering_location      = each.value.Peering_location
  bandwidth_in_mbps     =each.value.Bandwidth_in_mbps

  sku {
    tier   = each.value.Tier
    family = each.value.Family
  }

  tags = {
    environment = "Production"
  }
 # depends_on = [azurerm_resource_group.lz_rg]
}

resource "azurerm_subnet" "lz_gateway_subnet" {
  for_each =  { for k in local.lz.Gatwaysubnet : k.Name => k}
  name                 = "GatewaySubnet"
  resource_group_name  = each.value.Resource_group_name
  virtual_network_name = each.value.Vnet_Name
  address_prefixes     = [each.value.Address_Space]
  depends_on = [azurerm_virtual_network.lz_vnet]
}

resource "azurerm_local_network_gateway" "onpremise" {
  for_each =  { for k in local.lz.Localgateway : k.Name => k}
  name                = each.value.Name
  location            = each.value.Region
  resource_group_name = each.value.Resource_group_name
  gateway_address     = each.value.Gateway_address
  address_space       = [each.value.Address_space]
}

resource "azurerm_public_ip" "lz_pubip" {
  for_each =  { for k in local.lz.Localgateway : k.Publicip_Name => k}
  name                = each.value.Publicip_Name
  location            = each.value.Region
  resource_group_name = each.value.Resource_group_name
  allocation_method   = "Dynamic"
}


resource "azurerm_virtual_network_gateway" "lz_virnetworkgateway" {
  for_each =  { for k in local.lz.VirtualNetworkgateway : k.Name => k}
  name                = each.value.Name
  location            = each.value.Region
  resource_group_name = each.value.Resource_group_name

  type     = each.value.Type
  vpn_type = each.value.vpn_type

  active_active = false
  enable_bgp    = false
  sku           = each.value.sku

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.lz_pubip["Publicip_Name"].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.lz_gateway_subnet["Name"].id
  }
}


/*
resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  count = length(local.lz.VirtualNetworkgateway)
  name                = "${lookup(element(local.lz.VirtualNetworkgateway, count.index), "Name")}-connect"
  location            = azurerm_resource_group.lz_rg[0].location
  resource_group_name = azurerm_resource_group.lz_rg[0].name

  type     = lookup(element(local.lz.VirtualNetworkgateway, count.index), "Type")
  virtual_network_gateway_id = azurerm_virtual_network_gateway.lz_virnetworkgateway[count.index].id
  authorization_key  = azurerm_express_route_circuit.lz_connect[count.index].service_key
  express_route_circuit_id = azurerm_express_route_circuit.lz_connect[count.index].id
}


resource "azurerm_express_route_circuit_peering" "example" {
  peering_type                  = "MicrosoftPeering"
  express_route_circuit_name    = azurerm_express_route_circuit.example.name
  resource_group_name           = azurerm_resource_group.example.name
  peer_asn                      = 100
  primary_peer_address_prefix   = "123.0.0.0/30"
  secondary_peer_address_prefix = "123.0.0.4/30"
  vlan_id                       = 300

  microsoft_peering_config {
    advertised_public_prefixes = ["123.1.0.0/24"]
  }

  ipv6 {
    primary_peer_address_prefix   = "2002:db01::/126"
    secondary_peer_address_prefix = "2003:db01::/126"

    microsoft_peering {
      advertised_public_prefixes = ["2002:db01::/126"]
    }
  }
}
*/
