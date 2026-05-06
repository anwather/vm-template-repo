output "vm_id" {
  description = "Resource ID of the Windows VM."
  value       = azurerm_windows_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the Windows VM."
  value       = azurerm_windows_virtual_machine.this.name
}

output "resource_group_name" {
  description = "Resource group containing the VM."
  value       = local.resource_group_name
}

output "private_ip_address" {
  description = "Primary private IP address of the VM's NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the VM (null if create_public_ip is false). Resolved after apply."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "principal_id" {
  description = "Principal ID of the SystemAssigned managed identity (null if not enabled)."
  value       = var.enable_system_assigned_identity ? azurerm_windows_virtual_machine.this.identity[0].principal_id : null
}

output "admin_username" {
  description = "Local admin username configured on the VM."
  value       = azurerm_windows_virtual_machine.this.admin_username
}

output "admin_password_secret_id" {
  description = "Resource ID of the Key Vault secret holding the generated admin password."
  value       = azurerm_key_vault_secret.admin_password.id
}

output "admin_password_secret_name" {
  description = "Name of the Key Vault secret holding the generated admin password."
  value       = azurerm_key_vault_secret.admin_password.name
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault used to store the admin password."
  value       = data.azurerm_key_vault.this.id
}

output "data_disk_ids" {
  description = "Map of data disk name suffix => managed disk resource ID."
  value       = { for k, d in azurerm_managed_disk.data : k => d.id }
}
