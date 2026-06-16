resource "azurerm_storage_account" "this" {
  name                            = var.account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true
  tags                            = var.tags
}

resource "azurerm_storage_container" "media" {
  name                  = var.media_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "tiles" {
  name                  = var.tile_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "blob"
}
