variable "name" {
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

variable "owner_tag" {
  type = "string"
}

variable "environment_tag" {
  type = "string"
}

variable "internal_network_address_spaces" {
  type = "list"
}

variable "spoke_resource_group_name" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "spoke_network_name" {
  type = "string"
}

variable "spoke_network_address_spaces" {
  type = "list"
}

variable "dns_servers" {
  type = "list"
}

variable "spoke_subnet_1_name" {
  type = "string"
}

variable "spoke_subnet_1_address_space" {
  type = "string"
}

variable "hub_subscription_id" {
  type = "string"
}

variable "hub_resource_group_name" {
  type = "string"
}

variable "hub_network_name" {
  type = "string"
}

variable "hub_network_id" {
  type = "string"
}

variable "use_remote_gateways" {
  type = "string"
}
