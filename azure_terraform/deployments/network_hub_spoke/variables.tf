variable "customer_name" {
  type = "string"
}

variable "customer_prefix" {
  type = "string"
}

variable "tenant_id" {
  type = "string"
}

variable "subscription_id" {
  type = "string"
}

variable "internal_network_address_spaces" {
  type = "list"
}

variable "hub_resource_group_name" {
  type = "string"
}

variable "hub_owner_tag" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "dns_servers" {
  type    = "list"
  default = []
}

variable "hub_network_name" {
  type = "string"
}

variable "hub_network_address_spaces" {
  type = "list"
}

variable "hub_management_subnet_address_space" {
  type = "string"
}

variable "hub_active_directory_subnet_address_space" {
  type = "string"
}

variable "hub_shared_resource_subnet_address_space" {
  type = "string"
}

### Needed with Gateway configurations ###

variable "hub_gateway_subnet_address_space" {
  type    = "string"
  default = ""
}

### Used for VPN configurations ###

variable "create_vpn_gateway" {
  type    = "string"
  default = "false"
}

variable "hub_vpn_type" {
  type    = "string"
  default = "RouteBased"
}

variable "is_bgp_enabled" {
  type    = "string"
  default = false
}

variable "hub_vpn_gateway_bgp_asn" {
  type    = "string"
  default = ""
}

variable "hub_local_gateway_name" {
  type    = "string"
  default = ""
}

variable "hub_local_gateway_address" {
  type    = "string"
  default = ""
}

variable "hub_local_gateway_address_spaces" {
  type    = "list"
  default = []
}

variable "hub_local_gateway_bgp_asn" {
  type    = "string"
  default = ""
}

variable "hub_local_gateway_bgp_peering_address" {
  type    = "string"
  default = ""
}

variable "hub_vpn_connection_name" {
  type    = "string"
  default = ""
}

variable "hub_vpn_connection_shared_key" {
  type    = "string"
  default = ""
}

### Used for ExpressRoute configurations ###

variable "create_er_gateway" {
  type    = "string"
  default = "false"
}

variable "service_provider_name" {
  type    = "string"
  default = ""
}

variable "peering_location" {
  type    = "string"
  default = ""
}

variable "bandwidth_in_mbps" {
  type    = "string"
  default = ""
}

### Copy the below lines and change naming convention to 'spoke_x' ###
### The module itself must be duplicated and renamed in main.tf ###
### Two spokes have been created as an example ###

### Spoke 1 ###

variable "spoke_1_subscription_id" {
  type = "string"
}

variable "spoke_1_resource_group_name" {
  type = "string"
}

variable "spoke_1_owner_tag" {
  type = "string"
}

variable "spoke_1_environment_tag" {
  type = "string"
}

variable "spoke_1_network_name" {
  type = "string"
}

variable "spoke_1_network_address_spaces" {
  type = "list"
}

variable "spoke_1_subnet_1_name" {
  type = "string"
}

variable "spoke_1_subnet_1_address_space" {
  type = "string"
}

### Spoke 2 ###

variable "spoke_2_subscription_id" {
  type = "string"
}

variable "spoke_2_resource_group_name" {
  type = "string"
}

variable "spoke_2_owner_tag" {
  type = "string"
}

variable "spoke_2_environment_tag" {
  type = "string"
}

variable "spoke_2_network_name" {
  type = "string"
}

variable "spoke_2_network_address_spaces" {
  type = "list"
}

variable "spoke_2_subnet_1_name" {
  type = "string"
}

variable "spoke_2_subnet_1_address_space" {
  type = "string"
}
