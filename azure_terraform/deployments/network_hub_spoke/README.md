# Azure Cloud Start

To create a Cloud Start project for a new or existing customer, please follow the instructions below.

This terraform template consists of a Hub and Spoke topology by default.
* The Hub can be deployed by itself, or deployed with a VPN Gateway (BGP optional) and/or an ExpressRoute gateway. This VNet consists of a Management, Active Directory and Shared Access subnet, in addition to a Gateway Subnet created if a Gateway is being deployed.
* Two Spokes are deployed with peering to the Hub, and a single subnet each.
  * At current the module supports a single subnet by default. It would likely be best to create additional ones manually and associate the NSG to it. 
* A default NSG is created for each VNet with a default rule to allow the provided internal addresses access to the VNets.
* Policies are created to enforce tagging, limit deployment to UK locations and limit the VM SKUs that can be deployed.

If the default template is not adequate, then the Terraform files can be modified to be made more in-line with the design. See section 5 for information on adding and removing spokes.

---

## 1. Prerequisites

Prior to running through a Cloudstart you need the following:
* [Git](https://git-scm.com/)
* [Powershell](https://github.com/PowerShell/PowerShell)
* [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Terraform](https://www.terraform.io/)
* Excel for manipulating spreadsheets

These can mostly be installed with the instructions on the site or often through a package manager such as yum/apt, homebrew or chocolatey.

In addition to these packages, [VS Code](https://code.visualstudio.com/) is a useful, extensible code editor with plug-ins for Git, Terraform and more.

## 2. Preparing the template

1. Open the "Terraform Cloudstart.xlsx" file in Excel. For every hub/spoke environment that is being created, copy the first sheet. Do not change the "VariableName" values as these values are used later.
    * Any variables with the type "List" are comma-delimited. The "Build_Variables.ps1" script addresses and parses lists.

2. For each hub/spoke environment, do the following:
    * Create a copy of the 'deployment' folder
    * Copy the entire table in the spreadsheet from the "VariableName" section and paste it into a new "terraform.variables.csv"

3. Based on your requirements, make the below modifications to the modules:
    * Modify "modules/policies/main.tf" to ensure that the correct locations are in the list under the "policy-allow-locations-assignment" resource, and the "policy-tags-TAG-assignment" has a tag resource for all tags needed.
    * Modify "modules/hub/main.tf" and "modules/spoke/main.tf" NSGs to ensure they provide the necessary rules. By default they have a boilerplate configuration to allow anything in "internal_network_address_spaces" to communicate with the subnet range of the VNet that module creates.

4. Within the Azure environment, create a Management Group so that the tenant is initialized for Management Groups

5. The following commands will provision your infrastructure for a single deployment. Ensure that at the command line you are in the git repository.

```bash
cd deployment/ # Change directory to the deployment

../Build_Variables.ps1 [VARIABLES_CSV] # Run this command to generate the resources Terraform needs. It will look for "./terraform.variables.csv" by default. This must be ran with Powershell or Powershell Core depending on platform.

az login --subscription SUBSCRIPTION_ID # Log into Azure

terraform init # Download the Terraform plugins necessary for deployment, and pull the modules down for use.

terraform apply -target module.hub 
# This will create the Hub module, necessary to be created first as it carries some dependencies for Spoke modules. It will provide information on what is to be created, and prompt for you to continue.

terraform apply # This will create all other modules within the Terraform template, including all spokes and policies.
```

6. Save all open files, Git commit them to your local repository then Git push them back to GitLab for future reference.

```bash
git add .
git commit -m "YOUR_MESSAGE"
git push
```

---

## 3. Adding spokes

When adding a spoke, you must make changes in your Excel spreadsheet, "main.tf" and "variables.tf" files. 

1. Copy a "Spoke" row in the spreadsheet and increment the spoke number by one.

2. The new spoke must be set up in the Terraform "main.tf" and "variables.tf" files, for example:

main.tf
```terraform
module "spoke-2" {
  source = "../modules/spoke"
  name = "spoke-2"
  spoke_resource_group_name = "${var.spoke_2_resource_group_name}"
  <omitted>
}

module "spoke-3" {
  source = "../modules/spoke"
  name = "spoke-3"
  spoke_resource_group_name = "${var.spoke_3_resource_group_name}"
  <omitted>
}
```

variables.tf
```
variable "spoke_2_resource_group_name" {
    type = "string"
}
<omitted>
variable "spoke_3_resource_group_name" {
    type = "string"
}
<omitted>
```

