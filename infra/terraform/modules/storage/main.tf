resource "azurerm_storage_account" "this" {
  name                            = var.account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true

  dynamic "blob_properties" {
    for_each = length(var.tile_cors_allowed_origins) > 0 ? [1] : []

    content {
      cors_rule {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS"]
        allowed_origins    = var.tile_cors_allowed_origins
        exposed_headers    = ["Accept-Ranges", "Content-Length", "Content-Range", "Content-Type", "ETag", "Last-Modified", "Cache-Control"]
        max_age_in_seconds = 3600
      }
    }
  }

  tags = var.tags
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
