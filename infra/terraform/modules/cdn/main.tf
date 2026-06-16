resource "azurerm_cdn_profile" "this" {
  name                = var.profile_name
  location            = "Global"
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_cdn_endpoint" "this" {
  name                          = var.endpoint_name
  profile_name                  = azurerm_cdn_profile.this.name
  location                      = "Global"
  resource_group_name           = var.resource_group_name
  querystring_caching_behaviour = var.querystring_caching_behaviour
  is_http_allowed               = false
  is_https_allowed              = true
  origin_host_header            = var.origin_host_name
  tags                          = var.tags

  origin {
    name      = "blob-origin"
    host_name = var.origin_host_name
  }
}
