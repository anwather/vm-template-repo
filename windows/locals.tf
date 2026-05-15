###############################################################################
# Image map — the SINGLE source of truth for what each os_image string deploys.
# When you add a new os_image option, add a row here and update both the agent
# instructions and the function validator in the vm-build-agent repo.
###############################################################################

locals {
  image_map = {
    "WindowsServer2022-smalldisk" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-smalldisk"
      version   = "latest"
    }
    "WindowsServer2025-smalldisk" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2025-datacenter-smalldisk"
      version   = "latest"
    }
  }

  image = local.image_map[var.os_image]

  existing_resource_group = try(data.azurerm_resources.resource_group.resources[0], null)
  resource_group_exists   = local.existing_resource_group != null
  resource_group_name = coalesce(
    try(local.existing_resource_group.name, null),
    try(azurerm_resource_group.this[0].name, null),
  )
  resource_group_location = coalesce(
    try(local.existing_resource_group.location, null),
    try(azurerm_resource_group.this[0].location, null),
  )

  nic_name      = "${var.vm_name}-nic"
  os_disk_name  = "${var.vm_name}-osdisk"
  ipconfig_name = "ipconfig1"

  common_tags = {
    "managed-by"  = "terraform"
    "deployed-by" = "vm-build-agent"
    "vm-name"     = var.vm_name
    "os-image"    = var.os_image
  }
}
