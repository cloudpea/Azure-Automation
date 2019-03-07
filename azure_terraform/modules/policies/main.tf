resource "azurerm_management_group" "policy-mgmt-grp" {
  group_id = "${lower(var.customer_prefix)}rootmg"
  display_name = "${var.customer_prefix} Root MG"
  subscription_ids = "${var.management_group_subscriptions}"
}

resource "azurerm_policy_definition" "policy-allow-locations-definition" {
  name = "allowed-locations-policy-definition"
  management_group_id = "${azurerm_management_group.policy-mgmt-grp.group_id}"
  policy_type = "Custom"
  mode = "All"
  display_name = "${var.customer_prefix} Allowed Locations"
  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "location",
        "notIn": "[parameters('listOfAllowedLocations')]"
      },
      {
        "field": "location",
        "notEquals": "global"
      },
      {
        "field": "type",
        "notEquals": "Microsoft.AzureActiveDirectory/b2cDirectories"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfAllowedLocations": {
      "type": "Array",
      "metadata": {
        "description": "The list of allowed locations for resources.",
        "displayName": "${var.customer_prefix} Allowed Locations",
        "strongType": "location"
      }
    }
  }
PARAMETERS

  lifecycle {
    ignore_changes = [
      "metadata"
    ]
  }
}

resource "azurerm_policy_assignment" "policy-allow-locations-assignment" {
  name = "pol-allow-locations"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-allow-locations-definition.id}"
  description = "Policy Assignment to restrict locations"
  display_name = "${var.customer_prefix} Allowed Locations"
  parameters = <<PARAMETERS
{
  "listOfAllowedLocations": {
    "value": [
      "westeurope",
      "northeurope"
    ]
  }
}
PARAMETERS
}

resource "azurerm_policy_definition" "policy-allow-vm-skus-definition" {
  name = "allowed-vm-skus-policy-definition"
  management_group_id = "${azurerm_management_group.policy-mgmt-grp.group_id}"
  policy_type = "Custom"
  mode = "All"
  display_name = "${var.customer_prefix} Allowed virtual machine SKUs"
  policy_rule  = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",                                                                                              
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "field": "Microsoft.Compute/virtualMachines/sku.name",
          "in": "[parameters('listOfAllowedSKUs')]"
        }
      }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfAllowedSKUs": {
      "type": "Array",
      "metadata": {
        "description": "The list of allowed VM SKUs for resources.",
        "displayName": "${var.customer_prefix} Allowed virtual machine SKUs",
        "strongType": "type"
      }
    }
  }
PARAMETERS

  lifecycle {
    ignore_changes = [
      "metadata"
    ]
  }
}

resource "azurerm_policy_assignment" "policy-allow-vm-sku-assignment" {
  name = "pol-allow-vm-sku"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-allow-vm-skus-definition.id}"
  description = "Policy assignment to restrict VM SKUs"
  display_name = "${var.customer_prefix} Allowed virtual machine SKUs"
  parameters = <<PARAMETERS
{
  "listOfAllowedSKUs": {
  	"value": [
      "Standard_LRS",
      "Standard_LRS",
      "Standard_B1ms",
      "Standard_B1s",
      "Standard_B2ms",
      "Standard_B2s",
      "Standard_B4ms",
      "Standard_B8ms",
      "Standard_A0",
      "Standard_A1",
      "Standard_A2",
      "Standard_A3",
      "Standard_A5",
      "Standard_A4",
      "Standard_A6",
      "Standard_A7",
      "Basic_A0",
      "Basic_A1",
      "Basic_A2",
      "Basic_A3",
      "Basic_A4",
      "Standard_D1_v2",
      "Standard_D2_v2",
      "Standard_D3_v2",
      "Standard_D4_v2",
      "Standard_D5_v2",
      "Standard_D11_v2",
      "Standard_D12_v2",
      "Standard_D13_v2",
      "Standard_D14_v2",
      "Standard_D15_v2",
      "Standard_D2_v2_Promo",
      "Standard_D3_v2_Promo",
      "Standard_D4_v2_Promo",
      "Standard_D5_v2_Promo",
      "Standard_D11_v2_Promo",
      "Standard_D12_v2_Promo",
      "Standard_D13_v2_Promo",
      "Standard_D14_v2_Promo",
      "Standard_F1",
      "Standard_F2",
      "Standard_F4",
      "Standard_F8",
      "Standard_F16",
      "Standard_DS1_v2",
      "Standard_DS2_v2",
      "Standard_DS3_v2",
      "Standard_DS4_v2",
      "Standard_DS5_v2",
      "Standard_DS11-1_v2",
      "Standard_DS11_v2",
      "Standard_DS12-1_v2",
      "Standard_DS12-2_v2",
      "Standard_DS12_v2",
      "Standard_DS13-2_v2",
      "Standard_DS13-4_v2",
      "Standard_DS13_v2",
      "Standard_DS14-4_v2",
      "Standard_DS14-8_v2",
      "Standard_DS14_v2",
      "Standard_DS15_v2",
      "Standard_DS2_v2_Promo",
      "Standard_DS3_v2_Promo",
      "Standard_DS4_v2_Promo",
      "Standard_DS5_v2_Promo",
      "Standard_DS11_v2_Promo",
      "Standard_DS12_v2_Promo",
      "Standard_DS13_v2_Promo",
      "Standard_DS14_v2_Promo",
      "Standard_F1s",
      "Standard_F2s",
      "Standard_F4s",
      "Standard_F8s",
      "Standard_F16s",
      "Standard_A1_v2",
      "Standard_A2m_v2",
      "Standard_A2_v2",
      "Standard_A4m_v2",
      "Standard_A4_v2",
      "Standard_A8m_v2",
      "Standard_A8_v2",
      "Standard_D2_v3",
      "Standard_D4_v3",
      "Standard_D8_v3",
      "Standard_D16_v3",
      "Standard_D32_v3",
      "Standard_D2s_v3",
      "Standard_D4s_v3",
      "Standard_D8s_v3",
      "Standard_D16s_v3",
      "Standard_D32s_v3",
      "Standard_D64_v3",
      "Standard_D64s_v3",
      "Standard_E2_v3",
      "Standard_E4_v3",
      "Standard_E8_v3",
      "Standard_E16_v3",
      "Standard_E32_v3",
      "Standard_E64i_v3",
      "Standard_E64_v3",
      "Standard_E2s_v3",
      "Standard_E4-2s_v3",
      "Standard_E4s_v3",
      "Standard_E8-2s_v3",
      "Standard_E8-4s_v3",
      "Standard_E8s_v3",
      "Standard_E16-4s_v3",
      "Standard_E16-8s_v3",
      "Standard_E16s_v3",
      "Standard_E32-8s_v3",
      "Standard_E32-16s_v3",
      "Standard_E32s_v3",
      "Standard_E64-16s_v3",
      "Standard_E64-32s_v3",
      "Standard_E64is_v3",
      "Standard_E64s_v3",
      "Standard_H8",
      "Standard_H16",
      "Standard_H8m",
      "Standard_H16m",
      "Standard_H16r",
      "Standard_H16mr",
      "Standard_G1",
      "Standard_G2",
      "Standard_G3",
      "Standard_G4",
      "Standard_G5",
      "Standard_GS1",
      "Standard_GS2",
      "Standard_GS3",
      "Standard_GS4",
      "Standard_GS4-4",
      "Standard_GS4-8",
      "Standard_GS5",
      "Standard_GS5-8",
      "Standard_GS5-16",
      "Standard_L4s",
      "Standard_L8s",
      "Standard_L16s",
      "Standard_L32s"
    ]
  }
}
PARAMETERS
}

resource "azurerm_policy_definition" "policy-tags-definition" {
  name = "tags-policy-definition"
  management_group_id = "${azurerm_management_group.policy-mgmt-grp.group_id}"
  policy_type = "Custom"
  mode = "All"
  display_name = "${var.customer_prefix} Apply tag and its default value"
  policy_rule = <<POLICY_RULE
{
  "if": {
    "field": "[concat('tags[', parameters('tagName'), ']')]",
    "exists": "false"
  },
  "then": {
    "effect": "append",
    "details": [
      {
        "field": "[concat('tags[', parameters('tagName'), ']')]",
        "value": "[parameters('tagValue')]"
      }
    ]
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "tagName": {
      "type": "String",
      "metadata": {
        "description": "The Required Tag Name.",
        "displayName": "${var.customer_prefix} required tag name"
      }
    },
    "tagValue": {
      "type": "String",
      "metadata": {
        "description": "The Required Tag Value.",
        "displayName": "${var.customer_prefix} required tag value."
      }
    }
  }
PARAMETERS

  lifecycle {
    ignore_changes = [
      "metadata"
    ]
  }
}

resource "azurerm_policy_assignment" "policy-tags-owner-assignment" {
  name = "pol-tags-owner"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Owner tag"
  display_name = "Apply Owner Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Owner"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-project-assignment" {
  name = "pol-tags-project"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Project tag"
  display_name = "Apply Project Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Project"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-service-assignment" {
  name = "pol-tags-service"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Service tag"
  display_name = "Apply Service Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Service"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-app-id-assignment" {
  name = "pol-tags-app-id"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Application ID tag"
  display_name = "Apply Application ID Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Application ID"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-version-assignment" {
  name = "pol-tags-version"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Version tag"
  display_name = "Apply Version Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Version"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-tier-assignment" {
  name = "pol-tags-tier"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Tier tag"
  display_name = "Apply Tier Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Tier"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-app-roles-assignment" {
  name = "pol-tags-app-roles"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Application Roles tag"
  display_name = "Apply Application Roles Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Application Roles"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-environment-assignment" {
  name = "pol-tags-environment"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Environment tag"
  display_name = "Apply Environment Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Environment"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-business-unit-assignment" {
  name = "pol-tags-business-unit"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Business Unit tag"
  display_name = "Apply Business Unit Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Business Unit"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-cost-centre-assignment" {
  name = "pol-tags-cost-centre"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce Cost Centre tag"
  display_name = "Apply Cost Centre Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Cost Centre"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}

resource "azurerm_policy_assignment" "policy-tags-budget-assignment" {
  name = "pol-tags-${lower(var.customer_prefix)}-budget"
  scope = "${azurerm_management_group.policy-mgmt-grp.id}"
  policy_definition_id = "${azurerm_policy_definition.policy-tags-definition.id}"
  description = "Policy Assignment to enforce ${var.customer_prefix} Budget tag"
  display_name = "Apply ${var.customer_prefix} Budget Tag"
  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "${var.customer_prefix} Budget"
  },
  "tagValue": {
    "value": "Unknown"
  }
}
PARAMETERS
}
