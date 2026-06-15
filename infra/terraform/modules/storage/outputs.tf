output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  value = trimsuffix(trimprefix(azurerm_storage_account.this.primary_blob_endpoint, "https://"), "/")
}

output "media_container_name" {
  value = azurerm_storage_container.media.name
}

output "tile_container_name" {
  value = azurerm_storage_container.tiles.name
}
