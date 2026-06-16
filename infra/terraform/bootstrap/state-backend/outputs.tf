output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "staging_state_key" {
  value = var.staging_state_key
}

output "prod_state_key" {
  value = var.prod_state_key
}

output "staging_backend_config_example" {
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = var.staging_state_key
    use_azuread_auth     = true
  }
}

output "prod_backend_config_example" {
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = var.prod_state_key
    use_azuread_auth     = true
  }
}
