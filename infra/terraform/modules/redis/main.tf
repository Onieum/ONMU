resource "azurerm_managed_redis" "this" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.sku_name
  public_network_access     = var.public_network_access
  high_availability_enabled = var.high_availability_enabled
  tags                      = var.tags

  default_database {
    access_keys_authentication_enabled = var.default_database.access_keys_authentication_enabled
    client_protocol                    = var.default_database.client_protocol
    clustering_policy                  = var.default_database.clustering_policy
    eviction_policy                    = var.default_database.eviction_policy
  }
}
