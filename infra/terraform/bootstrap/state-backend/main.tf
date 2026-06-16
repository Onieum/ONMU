locals {
  state_writer_principals = setunion(
    var.operator_principal_object_ids,
    var.github_actions_principal_object_ids
  )
}

resource "azurerm_resource_group" "tfstate" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "tfstate" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.tfstate[0].name : data.azurerm_resource_group.tfstate[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.tfstate[0].id : data.azurerm_resource_group.tfstate[0].id
}

resource "azurerm_storage_account" "tfstate" {
  name                              = var.storage_account_name
  resource_group_name               = local.resource_group_name
  location                          = var.location
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
  count                 = var.create_state_container ? 1 : 0
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_management_lock" "tfstate_storage_account" {
  count      = var.enable_storage_account_delete_lock ? 1 : 0
  name       = "lock-${azurerm_storage_account.tfstate.name}-cannot-delete"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protect ONMU Terraform state backend storage from accidental deletion."
}

resource "azurerm_role_assignment" "tfstate_blob_data_contributor" {
  for_each             = local.state_writer_principals
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "tfstate_reader" {
  for_each             = local.state_writer_principals
  scope                = local.resource_group_id
  role_definition_name = "Reader"
  principal_id         = each.value
}
