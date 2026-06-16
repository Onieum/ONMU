locals {
  state_writer_principals = setunion(
    var.operator_principal_object_ids,
    var.github_actions_principal_object_ids
  )
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                              = var.storage_account_name
  resource_group_name               = azurerm_resource_group.tfstate.name
  location                          = azurerm_resource_group.tfstate.location
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.replication_type
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  tags                              = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "tfstate_blob_data_contributor" {
  for_each             = local.state_writer_principals
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "tfstate_reader" {
  for_each             = local.state_writer_principals
  scope                = azurerm_resource_group.tfstate.id
  role_definition_name = "Reader"
  principal_id         = each.value
}
