# Create Azure Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resourcegroup_name}"
  location = "${var.location}"

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }
}

# Create Azure Resource Group Lock
resource "azurerm_management_lock" "resourcegroup_lock" {
  name       = "delete_lock"
  scope      = "${azurerm_resource_group.resource_group.id}"
  lock_level = "CanNotDelete"
  notes      = "This Resource Group cannot be deleted."

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create an Azure Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.aks_cluster_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resourcegroup_name}"
  dns_prefix          = "${var.aks_dns_prefix}"

  role_based_access_control {
    enabled = true
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.node_count}"
    vm_size         = "${var.node_type}"
    os_type         = "Linux"
    os_disk_size_gb = "${var.node_disksize}"
  }

  network_profile {
    network_plugin     = "kubenet"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/24"
    pod_cidr           = "10.0.4.0/22"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  service_principal {
    client_id     = "${var.service_principal_application_id}"
    client_secret = "${var.service_principal_password}"
  }

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create an Azure Container Registry
resource "azurerm_container_registry" "container_registry" {
  name                = "${var.acr_name}"
  resource_group_name = "${var.resourcegroup_name}"
  location            = "${var.location}"
  admin_enabled       = false
  sku                 = "Basic"

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create an Azure Storage Account
resource "azurerm_storage_account" "testsa" {
  name                      = "${var.storage_account_name}"
  location                  = "${var.location}"
  resource_group_name       = "${var.resourcegroup_name}"
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  access_tier               = "Cool"
  enable_https_traffic_only = true

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create an Azure CLI Client Config
data "azurerm_client_config" "client_config" {}

# Create an Azure KeyVault
resource "azurerm_key_vault" "keyvault" {
  name                        = "${var.keyvault_name}"
  location                    = "${var.location}"
  resource_group_name         = "${var.resourcegroup_name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${data.azurerm_client_config.client_config.tenant_id}"

  sku {
    name = "standard"
  }

  access_policy {
    tenant_id = "${data.azurerm_client_config.client_config.tenant_id}"
    object_id = "${var.service_principal_object_id}"
    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]

    certificate_permissions = [
      "get",
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Outputs
output "aks_fqdn" {
  value = "${azurerm_kubernetes_cluster.aks_cluster.fqdn}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.aks_cluster.kube_config_raw}"
}

output "acr_server" {
  value = "${azurerm_container_registry.container_registry.login_server}"
}
