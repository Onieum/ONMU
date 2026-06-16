output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "runtime_identity_id" {
  value = azurerm_user_assigned_identity.runtime.id
}

output "runtime_identity_principal_id" {
  value = azurerm_user_assigned_identity.runtime.principal_id
}
