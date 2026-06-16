output "profile_id" {
  value = azurerm_cdn_frontdoor_profile.this.id
}

output "endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.this.id
}

output "endpoint_host_name" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "route_id" {
  value = azurerm_cdn_frontdoor_route.tiles_static.id
}
