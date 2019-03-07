# Create an application
resource "azuread_application" "ad_application" {
  name                       = "${var.ad_app_name}"
  homepage                   = "https://kubernetes.io"
  identifier_uris            = ["https://kubernetes.io"]
  reply_urls                 = ["https://kubernetes.io"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}
# Create a service principal
resource "azuread_service_principal" "service_principal" {
  application_id = "${azuread_application.ad_application.application_id}"
}
# Create a service principal password
resource "random_string" "password" {
  length = 32
  special = true
}
resource "azuread_service_principal_password" "service_principal_password" {
  service_principal_id = "${azuread_service_principal.service_principal.id}"
  value                = "${random_string.password.result}"
  end_date             = "2022-01-01T09:00:00Z"
}

# Outputs
output "service_principal_application_id" {
  value = "${azuread_application.ad_application.application_id}"
}
output "service_principal_object_id" {
  value = "${azuread_service_principal.service_principal.id}"
}
output "service_principal_password" {
  value = "${random_string.password.result}"
}