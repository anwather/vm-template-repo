###############################################################################
# Resource group (optional create, otherwise data lookup)
###############################################################################

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.this[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.this[0].id
}

###############################################################################
# Existing networking
###############################################################################

data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.this.name
  resource_group_name  = data.azurerm_virtual_network.this.resource_group_name
}

###############################################################################
# Existing Key Vault + generated admin password
###############################################################################

data "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

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
  override_special = "!@#$%^&*()-_=+[]{}"
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = local.secret_name
  value        = random_password.admin.result
  key_vault_id = data.azurerm_key_vault.this.id
  content_type = "Windows VM local admin password"
  tags         = local.common_tags
}

###############################################################################
# Public IP (optional)
###############################################################################

resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = local.public_ip_name
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = local.common_tags
}

###############################################################################
# NIC
###############################################################################

resource "azurerm_network_interface" "this" {
  name                = local.nic_name
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.common_tags

  ip_configuration {
    name                          = local.ipconfig_name
    subnet_id                     = data.azurerm_subnet.this.id
    private_ip_address_allocation = var.private_ip_allocation
    private_ip_address            = var.private_ip_allocation == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }
}

###############################################################################
# Windows VM
###############################################################################

resource "azurerm_windows_virtual_machine" "this" {
  name                = var.name
  computer_name       = var.name
  resource_group_name = local.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.admin.result
  tags                = local.common_tags

  network_interface_ids = [azurerm_network_interface.this.id]

  os_disk {
    name                 = local.os_disk_name
    caching              = try(var.os_disk.caching, "ReadWrite")
    storage_account_type = try(var.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb         = try(var.os_disk.disk_size_gb, null)
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = null
    }
  }

  # Ensure the password is in Key Vault before/with VM creation, so the agent
  # can always retrieve it even if VM creation later fails.
  depends_on = [azurerm_key_vault_secret.admin_password]
}

###############################################################################
# Data disks (optional, list of objects)
###############################################################################

resource "azurerm_managed_disk" "data" {
  for_each = { for d in var.data_disks : d.name_suffix => d }

  name                 = "${var.name}-${each.value.name_suffix}"
  resource_group_name  = local.resource_group_name
  location             = var.location
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  tags                 = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for d in var.data_disks : d.name_suffix => d }

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = each.value.lun
  caching            = each.value.caching
}
