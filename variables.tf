###############################################################################
# Variables — must match the contract emitted by the vm-build-agent runner
# (see runner/entrypoint.sh in the vm-build-agent repo). The runner writes
# terraform.tfvars.json with exactly these seven keys.
###############################################################################

variable "vm_name" {
  description = "Name of the Windows VM. Used as the OS computer name (must be 1–15 chars to satisfy the Windows NetBIOS limit)."
  type        = string

  validation {
    condition     = length(var.vm_name) >= 2 && length(var.vm_name) <= 15
    error_message = "vm_name must be between 2 and 15 characters (Windows NetBIOS computer name limit)."
  }
}

variable "resource_group" {
  description = "Resource group that will contain the VM. Created by this template if it doesn't already exist."
  type        = string
}

variable "location" {
  description = "Azure region for the VM and supporting resources (e.g. 'australiaeast')."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size, e.g. 'Standard_D2s_v5'."
  type        = string
}

variable "os_image" {
  description = "Logical OS image name. Must be one of the values in local.image_map."
  type        = string

  validation {
    condition = contains([
      "WindowsServer2022-smalldisk",
      "WindowsServer2025-smalldisk",
    ], var.os_image)
    error_message = "os_image must be one of: WindowsServer2022-smalldisk, WindowsServer2025-smalldisk."
  }
}

variable "admin_username" {
  description = "Local administrator username for the Windows VM."
  type        = string

  validation {
    condition     = !contains(["administrator", "admin", "user", "root", "guest"], lower(var.admin_username))
    error_message = "admin_username cannot be a reserved name (administrator, admin, user, root, guest)."
  }
}

variable "subnet_id" {
  description = "Full Azure resource ID of an existing subnet that the VM's NIC will attach to."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.subnet_id))
    error_message = "subnet_id must be a full subnet resource ID: /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  }
}
