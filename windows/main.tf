###############################################################################
# Resource group — reuse an existing RG when the name is already present in the
# subscription, otherwise create it here.
###############################################################################

data "azurerm_client_config" "current" {}

data "azapi_resource_list" "resource_groups" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

resource "azurerm_resource_group" "this" {
  count    = local.resource_group_exists ? 0 : 1
  name     = var.resource_group
  location = var.location
  tags     = local.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

###############################################################################
# Generated local-admin password (returned as a sensitive output).
# We avoid taking a Key Vault dependency so the agent can run in any landing
# zone without extra prerequisites.
###############################################################################

resource "random_password" "admin" {
  length           = 24
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!@#%^*()-_=+[]{}"
}

###############################################################################
# NIC — attaches to a pre-existing subnet supplied as a full ARM ID.
###############################################################################

resource "azurerm_network_interface" "this" {
  name                = local.nic_name
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.common_tags

  ip_configuration {
    name                          = local.ipconfig_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

###############################################################################
# Windows VM
###############################################################################

resource "azurerm_windows_virtual_machine" "this" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = local.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.common_tags

  network_interface_ids = [azurerm_network_interface.this.id]

  os_disk {
    name                 = local.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = local.image.publisher
    offer     = local.image.offer
    sku       = local.image.sku
    version   = local.image.version
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}
