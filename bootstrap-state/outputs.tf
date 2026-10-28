output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "State resource group name"
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Generated storage account name for backend.hcl"
}

output "container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "Blob container name for backend.hcl"
}

output "backend_config_snippet" {
  description = "Copy into cluster/backend.hcl before running terraform init"
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "aks/prod.tfstate"
    use_azuread_auth     = true
  EOT
}
