variable "resourcegroup_name" {default = "RG-PRD-UKS-CLOUDPEA-AKS"}
variable "location" {default = "UK South"}
variable "tag_application" {default = "CloudPea App"}
variable "tag_environment" {default = "Production"}
variable "tag_criticality" {default = "Tier 1"}
variable "tag_owner" {default = "Ryan Froggatt"}
variable "ad_app_name" {default = "ad_app_prd_uks_aks_cloudpea"}
variable "aks_cluster_name" {default = "AKS-PRD-UKS-CLOUDPEA"}
variable "aks_dns_prefix" {default = "cloudpea"}
variable "node_count" {default = "1"}
variable "node_type" {default = "Standard_B2s"}
variable "node_disksize" {default = "30"}
variable "acr_name" {default = "acrprdukscloudpea"}
variable "keyvault_name" {default = "KV-PRD-UKS-CLOUDPEA"}
variable "storage_account_name" {default = "saprdukscloudpea"}