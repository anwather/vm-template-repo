###############################################################################
# Identity & placement
###############################################################################

variable "name" {
  description = "Name of the Windows virtual machine. Used as the basis for related resource names (NIC, public IP, OS disk, KV secret) and as the OS computer name (must be 1-15 chars to be valid as a Windows computer name)."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 15
    error_message = "name must be between 1 and 15 characters (Windows computer name limit)."
  }
}

variable "location" {
  description = "Azure region for the VM and any resources created by this template (e.g. 'australiaeast')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will contain the VM. If create_resource_group is false, this RG must already exist."
  type        = string
}

variable "create_resource_group" {
  description = "If true, create the resource group named in resource_group_name. If false, the RG must already exist."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources created by this template."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking (existing vnet/subnet)
###############################################################################

variable "vnet_resource_group_name" {
  description = "Resource group containing the existing virtual network."
  type        = string
}

variable "vnet_name" {
  description = "Name of the existing virtual network the VM's NIC will attach to."
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing subnet (within vnet_name) for the VM's NIC."
  type        = string
}

variable "private_ip_allocation" {
  description = "Private IP allocation method for the NIC: 'Dynamic' or 'Static'."
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_allocation)
    error_message = "private_ip_allocation must be 'Dynamic' or 'Static'."
  }
}

variable "private_ip_address" {
  description = "Static private IP address. Required when private_ip_allocation is 'Static'; ignored otherwise."
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "If true, create a public IP and attach it to the VM's NIC."
  type        = bool
  default     = false
}

variable "public_ip_sku" {
  description = "SKU for the public IP when create_public_ip is true."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "public_ip_sku must be 'Basic' or 'Standard'."
  }
}

variable "public_ip_allocation_method" {
  description = "Allocation method for the public IP. Standard SKU requires 'Static'."
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "public_ip_allocation_method must be 'Static' or 'Dynamic'."
  }
}

###############################################################################
# Compute
###############################################################################

variable "vm_size" {
  description = "Azure VM size (e.g. 'Standard_D2s_v5')."
  type        = string
  default     = "Standard_D2s_v5"

  validation {
    condition     = length(var.vm_size) > 0
    error_message = "vm_size must not be empty."
  }
}

variable "admin_username" {
  description = "Local administrator username for the Windows VM."
  type        = string
  default     = "azureadmin"

  validation {
    condition     = !contains(["administrator", "admin", "user", "root", "guest"], lower(var.admin_username))
    error_message = "admin_username cannot be a Windows reserved name (administrator, admin, user, root, guest)."
  }
}

variable "os_disk" {
  description = "OS disk configuration."
  type = object({
    storage_account_type = optional(string, "Premium_LRS")
    disk_size_gb         = optional(number)
    caching              = optional(string, "ReadWrite")
  })
  default = {}
}

variable "data_disks" {
  description = "List of managed data disks to create and attach. Each entry: name_suffix (appended to VM name), disk_size_gb, lun, storage_account_type, caching."
  type = list(object({
    name_suffix          = string
    disk_size_gb         = number
    lun                  = number
    storage_account_type = optional(string, "Premium_LRS")
    caching              = optional(string, "ReadWrite")
  }))
  default = []
}

variable "enable_system_assigned_identity" {
  description = "If true, enable a SystemAssigned managed identity on the VM."
  type        = bool
  default     = false
}

variable "enable_boot_diagnostics" {
  description = "If true, enable boot diagnostics using a managed (platform-hosted) storage account."
  type        = bool
  default     = true
}

###############################################################################
# Marketplace image (defaults to Windows Server 2025 Datacenter Azure Edition - smalldisk)
###############################################################################

variable "image_publisher" {
  description = "Marketplace image publisher."
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "Marketplace image offer."
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "Marketplace image SKU. Default is the smalldisk variant of Windows Server 2025 Datacenter Azure Edition (~30 GB OS disk)."
  type        = string
  default     = "2025-datacenter-azure-edition-smalldisk"
}

variable "image_version" {
  description = "Marketplace image version, or 'latest'."
  type        = string
  default     = "latest"
}

###############################################################################
# Key Vault (existing) for admin password storage
###############################################################################

variable "key_vault_name" {
  description = "Name of the existing Azure Key Vault that the generated admin password will be stored in."
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Resource group containing the existing Key Vault."
  type        = string
}

variable "admin_password_secret_name" {
  description = "Name of the Key Vault secret to create/update with the generated admin password. Defaults to '<vm-name>-admin-password'."
  type        = string
  default     = null
}
