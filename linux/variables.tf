###############################################################################
# Variables — must match the contract emitted by the Linux VM-builder hosted
# agent's set_tf_variables tool.
###############################################################################

variable "vm_name" {
  description = "Name of the Linux VM. Used as the OS hostname."
  type        = string

  validation {
    condition     = length(var.vm_name) >= 1 && length(var.vm_name) <= 64
    error_message = "vm_name must be between 1 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vm_name))
    error_message = "vm_name must contain only lowercase letters, digits, and hyphens."
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
      "Ubuntu2204",
      "Ubuntu2404",
      "RHEL9",
    ], var.os_image)
    error_message = "os_image must be one of: Ubuntu2204, Ubuntu2404, RHEL9."
  }
}

variable "admin_username" {
  description = "Local administrator username for the Linux VM."
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
