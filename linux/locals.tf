###############################################################################
# Image map — single source of truth for what each os_image string deploys.
# When you add a new os_image option, add a row here and update the validation
# list in `variables.tf` and the agent's ALLOWED_OS_IMAGES_JSON env var.
###############################################################################

locals {
  image_map = {
    "Ubuntu2204" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
    "Ubuntu2404" = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
    "RHEL9" = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "9-lvm-gen2"
      version   = "latest"
    }
  }

  image = local.image_map[var.os_image]

  nic_name      = "${var.vm_name}-nic"
  os_disk_name  = "${var.vm_name}-osdisk"
  ipconfig_name = "ipconfig1"

  common_tags = {
    "managed-by"  = "terraform"
    "deployed-by" = "vm-build-agent-linux"
    "vm-name"     = var.vm_name
    "os-image"    = var.os_image
  }
}
