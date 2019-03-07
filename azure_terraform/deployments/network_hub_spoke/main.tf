provider "azurerm" {
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  version         = "~> 1.22"
}

### Create the Hub resources ###

module "hub" {
  source              = "../../modules/network/hub"
  name                = "hub"
  customer_prefix = "${var.customer_prefix}"

  # General parameters for the Hub
  hub_resource_group_name                   = "${var.hub_resource_group_name}"
  owner_tag                                     = "${var.hub_owner_tag}"
  hub_location                              = "${var.location}"
  hub_network_name                          = "${var.hub_network_name}"
  hub_network_address_spaces                = "${var.hub_network_address_spaces}"
  dns_servers                               = "${var.dns_servers}"
  hub_management_subnet_address_space       = "${var.hub_management_subnet_address_space}"
  hub_active_directory_subnet_address_space = "${var.hub_active_directory_subnet_address_space}"
  hub_shared_resource_subnet_address_space  = "${var.hub_shared_resource_subnet_address_space}"
  internal_network_address_spaces           = "${var.internal_network_address_spaces}"

  # GW Subnet only created if a Gateway will be created
  hub_gateway_subnet_address_space = "${var.hub_gateway_subnet_address_space}"

  # VPN Gateway options
  create_vpn_gateway                        = "${var.create_vpn_gateway}"
  hub_vpn_type                          = "${var.hub_vpn_type}"
  is_bgp_enabled                            = "${var.is_bgp_enabled}"
  hub_vpn_gateway_bgp_asn               = "${var.hub_vpn_gateway_bgp_asn}"
  hub_local_gateway_name                = "${var.hub_local_gateway_name}"
  hub_local_gateway_address             = "${var.hub_local_gateway_address}"
  hub_local_gateway_address_spaces      = "${var.hub_local_gateway_address_spaces}"
  hub_local_gateway_bgp_asn             = "${var.hub_local_gateway_bgp_asn}"
  hub_local_gateway_bgp_peering_address = "${var.hub_local_gateway_bgp_peering_address}"
  hub_vpn_connection_name               = "${var.hub_vpn_connection_name}"
  hub_vpn_connection_shared_key         = "${var.hub_vpn_connection_shared_key}"

  # ExpressRoute Gateway options
  create_er_gateway         = "${var.create_er_gateway}"
  service_provider_name = "${var.service_provider_name}"
  peering_location      = "${var.peering_location}"
  bandwidth_in_mbps     = "${var.bandwidth_in_mbps}"
}

### Spokes ###

module "spoke-1" {
  source              = "../../modules/network/spoke"
  name                = "spoke-1"
  customer_prefix = "${var.customer_prefix}"
  owner_tag     = "${var.spoke_1_owner_tag}"
  environment_tag     = "${var.spoke_1_environment_tag}"

  # General Spoke parameters
  tenant_id                    = "${var.tenant_id}"
  subscription_id              = "${var.spoke_1_subscription_id}"
  spoke_resource_group_name    = "${var.spoke_1_resource_group_name}"
  location                     = "${var.location}"
  spoke_network_name           = "${var.spoke_1_network_name}"
  spoke_network_address_spaces = "${var.spoke_1_network_address_spaces}"
  dns_servers                  = "${var.dns_servers}"
  spoke_subnet_1_name          = "${var.spoke_1_subnet_1_name}"
  spoke_subnet_1_address_space = "${var.spoke_1_subnet_1_address_space}"

  internal_network_address_spaces = "${var.internal_network_address_spaces}"

  # Used for the VNet Peering
  hub_subscription_id     = "${var.subscription_id}"
  hub_resource_group_name = "${module.hub.hub-rg-name}"
  hub_network_name        = "${module.hub.hub-net-name}"
  hub_network_id          = "${module.hub.hub-net-id}"
  use_remote_gateways         = "${module.hub.hub-gw-sn-count}"
}

module "spoke-2" {
  source              = "../../modules/network/spoke"
  name                = "spoke-2"
  customer_prefix = "${var.customer_prefix}"
  owner_tag     = "${var.spoke_2_owner_tag}"
  environment_tag     = "${var.spoke_2_environment_tag}"

  # General Spoke parameters
  tenant_id                    = "${var.tenant_id}"
  subscription_id              = "${var.spoke_2_subscription_id}"
  spoke_resource_group_name    = "${var.spoke_2_resource_group_name}"
  location                     = "${var.location}"
  spoke_network_name           = "${var.spoke_2_network_name}"
  spoke_network_address_spaces = "${var.spoke_2_network_address_spaces}"
  dns_servers                  = "${var.dns_servers}"
  spoke_subnet_1_name          = "${var.spoke_2_subnet_1_name}"
  spoke_subnet_1_address_space = "${var.spoke_2_subnet_1_address_space}"

  internal_network_address_spaces = "${var.internal_network_address_spaces}"

  # Used for the VNet Peering
  hub_subscription_id     = "${var.subscription_id}"
  hub_resource_group_name = "${module.hub.hub-rg-name}"
  hub_network_name        = "${module.hub.hub-net-name}"
  hub_network_id          = "${module.hub.hub-net-id}"
  use_remote_gateways         = "${module.hub.hub-gw-sn-count}"
}
