output "resource_group_name" {
  value = local.resource_group_name
}

output "subscription_display_name" {
  value = var.subscription_display_name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = var.container_name
}

output "state_container_id" {
  value = try(azurerm_storage_container.tfstate[0].id, null)
}

output "storage_account_delete_lock_id" {
  value = try(azurerm_management_lock.tfstate_storage_account[0].id, null)
}

output "bootstrap_state_key" {
  value = var.bootstrap_state_key
}

output "staging_state_key" {
  value = var.staging_state_key
}

output "prod_state_key" {
  value = var.prod_state_key
}

output "bootstrap_backend_config_example" {
  value = {
    resource_group_name  = local.resource_group_name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = var.container_name
    key                  = var.bootstrap_state_key
    use_azuread_auth     = true
  }
}

output "staging_backend_config_example" {
  value = {
    resource_group_name  = local.resource_group_name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = var.container_name
    key                  = var.staging_state_key
    use_azuread_auth     = true
  }
}

output "prod_backend_config_example" {
  value = {
    resource_group_name  = local.resource_group_name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = var.container_name
    key                  = var.prod_state_key
    use_azuread_auth     = true
  }
}
