output "id" {
  value = azurerm_managed_redis.this.id
}

output "hostname" {
  value = azurerm_managed_redis.this.hostname
}

output "port" {
  value = azurerm_managed_redis.this.default_database[0].port
}

output "source_of_truth" {
  value = false
}
