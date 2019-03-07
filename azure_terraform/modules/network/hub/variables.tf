variable "name" {
  type = "string"
}

variable "customer_prefix" {
  type = "string"
}

variable "owner_tag" {
  type = "string"
}

variable "internal_network_address_spaces" {
  type = "list"
}

variable "hub_resource_group_name" {
  type = "string"
}

variable "hub_location" {
  type = "string"
}

variable "dns_servers" {
  type = "list"
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
  type = "string"
  default = ""
}

### Used for VPN configurations ###

variable "create_vpn_gateway" {
  type = "string"
  default = "false"
}

variable "hub_vpn_type" {
  type = "string"
  default = "RouteBased"
}

variable "is_bgp_enabled" {
  type = "string"
  default = false
}

variable "hub_vpn_gateway_bgp_asn" {
  type = "string"
  default = ""
}

variable "hub_local_gateway_name" {
  type = "string"
  default = ""
}

variable "hub_local_gateway_address" {
  type = "string"
  default = ""
}

variable "hub_local_gateway_address_spaces" {
  type = "list"
  default = []
}

variable "hub_local_gateway_bgp_asn" {
  type = "string"
  default = ""
}

variable "hub_local_gateway_bgp_peering_address" {
  type = "string"
  default = ""
}

variable "hub_vpn_connection_name" {
  type = "string"
  default = ""
}

variable "hub_vpn_connection_shared_key" {
  type = "string"
  default = ""
}

### Used for ExpressRoute configurations ###

variable "create_er_gateway" {
  type = "string"
  default = "false"
}

variable "service_provider_name" {
  type = "string"
  default = ""
}

variable "peering_location" {
  type = "string"
  default = ""
}

variable "bandwidth_in_mbps" {
  type = "string"
  default = ""
}
