output "environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "spring_api_id" {
  value = var.create_spring_api_app ? azurerm_container_app.spring_api[0].id : null
}

output "spring_api_latest_revision_fqdn" {
  value = var.create_spring_api_app ? azurerm_container_app.spring_api[0].latest_revision_fqdn : null
}

output "worker_id" {
  value = var.worker.enabled ? azurerm_container_app.worker[0].id : null
}

output "worker_enabled" {
  value = var.worker.enabled
}
