# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "=0.1.0"
}

# Configure the Microsoft Azure Resource Manager Provider
provider "azurerm" {
  version = "=1.22.0"
}

# Configure the Random Provider
provider "random" {}

# Configure the Local Provider
provider "local" {}

# Set Azure Subsciption
data "azurerm_subscription" "current" {}

# Create Azure AD Objects
module "azure_ad" {
  source      = "../modules/azure_ad"
  ad_app_name = "${var.ad_app_name}"
}

# Create Azure Kubernetes Service, Container Registry, Storage Account and KeyVault
module "kubernetes" {
  source                           = "../../modules/kubernetes"
  resourcegroup_name               = "${var.resourcegroup_name}"
  location                         = "${var.location}"
  tag_application                  = "${var.tag_application}"
  tag_environment                  = "${var.tag_environment}"
  tag_criticality                  = "${var.tag_criticality}"
  tag_owner                        = "${var.tag_owner}"
  aks_cluster_name                 = "${var.aks_cluster_name}"
  aks_dns_prefix                   = "${var.aks_dns_prefix}"
  node_count                       = "${var.node_count}"
  node_type                        = "${var.node_type}"
  node_disksize                    = "${var.node_disksize}"
  service_principal_application_id = "${module.azure_ad.service_principal_application_id}"
  service_principal_password       = "${module.azure_ad.service_principal_password}"
  acr_name                         = "${var.acr_name}"
  storage_account_name             = "${var.storage_account_name}"
  keyvault_name                    = "${var.keyvault_name}"
  service_principal_object_id      = "${module.azure_ad.service_principal_object_id}"
}

resource "local_file" "outputs" {
    content     = 
    "Service Principal Application ID - ${module.azure_ad.service_principal_application_id}\nService Principal Object ID - ${module.azure_ad.service_principal_object_id}\nService Principal Password - ${module.azure_ad.service_principal_password}\nAKS FQDN - ${module.kubernetes.aks_fqdn}\nACR Server - ${module.kubernetes.acr_server}\nAKS Kube Config -\n${module.kubernetes.kube_config}\n"
    filename = "${path.module}/outputs.txt"
}

# Outputs
output "service_principal_application_id" {
  value = "${module.azure_ad.service_principal_application_id}"
}

output "service_principal_object_id" {
  value = "${module.azure_ad.service_principal_object_id}"
}

output "service_principal_password" {
  value = "${module.azure_ad.service_principal_password}"
}

output "aks_fqdn" {
  value = "${module.kubernetes.aks_fqdn}"
}

output "kube_config" {
  value = "${module.kubernetes.kube_config}"
}

output "acr_server" {
  value = "${module.kubernetes.acr_server}"
}
