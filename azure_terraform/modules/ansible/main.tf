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

# Create Azure Availability Set
resource "azurerm_availability_set" "av_set" {
  name                         = "AV-${var.vm_name}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resourcegroup_name}"
  managed                      = true
  platform_update_domain_count = 5
  platform_fault_domain_count  = 3

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create Azure Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "NSG-${var.vm_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resourcegroup_name}"

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.corporate_ip}"
    destination_address_prefix = "*"
  }

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create Azure VM Network Interfaces
resource "azurerm_network_interface" "nic" {
  name                      = "NIC-${var.vm_name}"
  location                  = "${var.location}"
  resource_group_name       = "${var.resourcegroup_name}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = ["azurerm_resource_group.resource_group"]
}

# Create Azure Virtual Machines
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.vm_name}"
  location              = "${var.location}"
  resource_group_name   = "${var.resourcegroup_name}"
  availability_set_id   = "${azurerm_availability_set.av_set.id}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "${var.vm_size}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "OS-${var.vm_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.vm_name}"
    admin_username = "${var.vm_username}"
    admin_password = "${var.vm_password}"
    custom_data    = "${data.template_file.cloudconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Application = "${var.tag_application}"
    Environment = "${var.tag_environment}"
    Criticality = "${var.tag_criticality}"
    Owner       = "${var.tag_owner}"
  }

  depends_on = [
    "azurerm_resource_group.resource_group",
    "azurerm_network_interface.nic",
  ]
}

data "template_file" "inventory_file" {
  template = "${file("${path.module}/inventory_file")}"
}

data "template_file" "cloudconfig" {
  template = "${file("${path.module}/InstallAnsible.sh")}"

  vars {
    ansible_username        = "${var.ansible_username}"
    inventory_file_contents = "${data.template_file.inventory_file.rendered}"
    ansible_git_url         = "${var.ansible_git_url}"
  }
}
