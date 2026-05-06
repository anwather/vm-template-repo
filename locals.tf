locals {
  nic_name       = "${var.name}-nic"
  public_ip_name = "${var.name}-pip"
  os_disk_name   = "${var.name}-osdisk"
  ipconfig_name  = "ipconfig1"
  secret_name    = coalesce(var.admin_password_secret_name, "${var.name}-admin-password")

  common_tags = merge(
    {
      "managed-by" = "terraform"
      "vm-name"    = var.name
    },
    var.tags,
  )
}
