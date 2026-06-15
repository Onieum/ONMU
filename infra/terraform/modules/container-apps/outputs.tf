output "environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "spring_api_id" {
  value = azurerm_container_app.spring_api.id
}

output "spring_api_latest_revision_fqdn" {
  value = azurerm_container_app.spring_api.latest_revision_fqdn
}

output "worker_id" {
  value = var.worker.enabled ? azurerm_container_app.worker[0].id : null
}

output "worker_enabled" {
  value = var.worker.enabled
}
