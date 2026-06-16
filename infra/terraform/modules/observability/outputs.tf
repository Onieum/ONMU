output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "application_insights_id" {
  value = azurerm_application_insights.this.id
}

output "application_insights_connection_string_secret_name" {
  value = "APPLICATIONINSIGHTS_CONNECTION_STRING"
}
