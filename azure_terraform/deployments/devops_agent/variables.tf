variable "resourcegroup_name" {
    default = "RG-PRD-UKS-DEVOPS"
}
variable "location" {
    default = "UK South"
}
variable "tag_application" {
    default = "Azure DevOps"
}
variable "tag_environment" {
    default = "Production"
}
variable "tag_criticality" {
    default = "Tier 2"
}
variable "tag_owner" {
    default = "Ryan Froggatt"
}
variable "vm_name" {
    default = "VM-PRD-UKS-DEVOPS-AGENT"
}
variable "vm_size" {
    default = "Standard_B1s"
}
variable "vm_username" {
    default = "cloudpea-admin"
}
variable "vm_password" {}
variable "corporate_ip" {
    default = "10.0.1.10"
}
variable "subnet_id" {
    default = ""
}
variable "devops_organisation" {
    default = "cloupea"
}
variable "devops_pat" {}
variable "devops_pool_name" {
    default = "cloudpea"
}