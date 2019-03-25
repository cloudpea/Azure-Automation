variable "resourcegroup_name" {
  type        = "string"
  default     = "RG-PRD-UKS-CLOUDPEA-AKS"
  description = "Resource Group Name for the Azure Kubernetes Resources."
}

variable "location" {
  type        = "string"
  default     = "UK South"
  description = "Location to Create the Azure Kubernetes Resources."
}

variable "tag_application" {
  type        = "string"
  default     = "CloudPea App"
  description = "An Application Tag for the Azure Kubernetes Resources."
}

variable "tag_environment" {
  type        = "string"
  default     = "Production"
  description = "An Environment Tag for the Azure Kubernetes Resources."
}

variable "tag_criticality" {
  type        = "string"
  default     = "Tier 1"
  description = "A Criticality Tag for the Azure Kubernetes Resources."
}

variable "tag_owner" {
  type        = "string"
  default     = "Ryan Froggatt"
  description = "An Owner Tag for the Azure Kubernetes Resources."
}

variable "ad_app_name" {
  type        = "string"
  default     = "ad_app_prd_uks_aks_cloudpea"
  description = "Name of the Azure AD Service Principal for the Kubernetes Cluster."
}

variable "aks_cluster_name" {
  type        = "string"
  default     = "AKS-PRD-UKS-CLOUDPEA"
  description = "Name of the Azure Kubernetes Cluster."
}

variable "aks_dns_prefix" {
  type        = "string"
  default     = "cloudpea"
  description = "DNS Prefix for the Azure Kubernetes Cluster."
}

variable "node_count" {
  type        = "string"
  default     = "1"
  description = "Number of Azure Kubernetes Worker Nodes."
}

variable "node_type" {
  type        = "string"
  default     = "Standard_B2s"
  description = "Size of the Azure Kubernetes Worker Nodes."
}

variable "node_disksize" {
  type        = "string"
  default     = "30"
  description = "OS Disk size of Azure Kubernetes Worker Nodes."
}

variable "acr_name" {
  type        = "string"
  default     = "acrprdukscloudpea"
  description = "Azure Container Registry Name."
}

variable "keyvault_name" {
  type        = "string"
  default     = "KV-PRD-UKS-CLOUDPEA"
  description = "Azure KeyVault Name."
}

variable "storage_account_name" {
  type        = "string"
  default     = "saprdukscloudpea"
  description = "Azure Storage Account Name."
}
