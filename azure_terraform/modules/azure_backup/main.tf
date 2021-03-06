# Create GRS Recovery Services Vault
resource "azurerm_recovery_services_vault" "vault_grs" {
  name                = "${var.vault_name}-GRS"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  provisioner "local-exec" {
    command     = "az backup vault backup-properties set --name ${var.vault_name}-GRS --resource-group ${var.resource_group_name} --backup-storage-redundancy GeoRedundant"
  }

  tags {
    Application = "Azure Backup"
    Owner       = "${var.tag_owner}"
  }
}

# Create LRS Recovery Services Vault
resource "azurerm_recovery_services_vault" "vault_lrs" {
  name                = "${var.vault_name}-LRS"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  provisioner "local-exec" {
    command     = "az backup vault backup-properties set --name ${var.vault_name}-LRS --resource-group ${var.resource_group_name} --backup-storage-redundancy LocallyRedundant"
  }

  tags {
    Application = "Azure Backup"
    Owner       = "${var.tag_owner}"
  }
}

# Create Tier 1 Protection Policies
resource "azurerm_recovery_services_protection_policy_vm" "policy_tier1" {
  name                = "BP-TIER1-GRS-${count.index}"
  count               = "${var.tier1_policy_count}"
  resource_group_name = "${var.resource_group_name}"
  recovery_vault_name = "${azurerm_recovery_services_vault.vault_grs.name}"

  timezone = "UTC"

  backup = {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily = {
    count = 30
  }

  retention_weekly = {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly = {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["Last"]
  }
}

# Create Tier 2 Protection Policies
resource "azurerm_recovery_services_protection_policy_vm" "policy_tier2" {
  name                = "BP-TIER2-GRS-${count.index}"
  count               = "${var.tier2_policy_count}"
  resource_group_name = "${var.resource_group_name}"
  recovery_vault_name = "${azurerm_recovery_services_vault.vault_grs.name}"

  timezone = "UTC"

  backup = {
    frequency = "Daily"
    time      = "01:00"
  }

  retention_daily = {
    count = 30
  }

  retention_weekly = {
    count    = 12
    weekdays = ["Sunday"]
  }
}

# Create Tier 3 Protection Policies
resource "azurerm_recovery_services_protection_policy_vm" "policy_tier3" {
  name                = "BP-TIER3-LRS-${count.index}"
  count               = "${var.tier3_policy_count}"
  resource_group_name = "${var.resource_group_name}"
  recovery_vault_name = "${azurerm_recovery_services_vault.vault_lrs.name}"

  timezone = "UTC"

  backup = {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily = {
    count = 7
  }

  retention_weekly = {
    count    = 7
    weekdays = ["Sunday"]
  }
}

# Create Tier 4 Protection Policies
resource "azurerm_recovery_services_protection_policy_vm" "policy_tier4" {
  name                = "BP-TIER4-LRS-${count.index}"
  count               = "${var.tier4_policy_count}"
  resource_group_name = "${var.resource_group_name}"
  recovery_vault_name = "${azurerm_recovery_services_vault.vault_lrs.name}"

  timezone = "UTC"

  backup = {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily = {
    count = 7
  }
}