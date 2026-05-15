output "vm_id" {
  description = "Resource ID of the Linux VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the Linux VM."
  value       = azurerm_linux_virtual_machine.this.name
}

output "resource_group" {
  description = "Resource group containing the VM."
  value       = local.resource_group_name
}

output "location" {
  description = "Azure region the VM was deployed to."
  value       = local.resource_group_location
}

output "os_image" {
  description = "Logical OS image name selected by the caller."
  value       = var.os_image
}

output "image_sku" {
  description = "Marketplace image SKU actually used (resolved from os_image)."
  value       = local.image.sku
}

output "private_ip_address" {
  description = "Primary private IP address of the VM's NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "admin_username" {
  description = "Local admin username configured on the VM."
  value       = azurerm_linux_virtual_machine.this.admin_username
}
