resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  zone                          = var.zone
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  lifecycle {
    # Azure may normalize or assign the zone after create; later app waves should
    # not try to mutate the database just because the reported zone drifted.
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  count     = length(var.enabled_extensions) > 0 ? 1 : 0
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = join(",", var.enabled_extensions)
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  depends_on = [
    azurerm_postgresql_flexible_server_configuration.extensions
  ]
}
