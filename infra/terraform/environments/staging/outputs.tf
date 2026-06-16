output "resource_group_name" {
  value = local.resource_group_name
}

output "log_analytics_workspace_id" {
  value = try(module.observability[0].log_analytics_workspace_id, null)
}

output "application_insights_id" {
  value = try(module.observability[0].application_insights_id, null)
}

output "container_registry_login_server" {
  value = try(module.container_registry[0].login_server, null)
}

output "spring_api_latest_revision_fqdn" {
  value = try(module.container_apps[0].spring_api_latest_revision_fqdn, null)
}

output "container_app_environment_id" {
  value = try(module.container_apps[0].environment_id, null)
}

output "postgres_fqdn" {
  value = try(module.postgres[0].fqdn, null)
}

output "redis_hostname" {
  value = try(module.redis[0].hostname, null)
}

output "blob_endpoint" {
  value = try(module.storage[0].primary_blob_endpoint, null)
}

output "cdn_endpoint_host_name" {
  value = try(module.cdn[0].endpoint_host_name, null)
}

output "frontdoor_endpoint_host_name" {
  value = try(module.front_door[0].endpoint_host_name, null)
}

output "eventhub_names" {
  value = try(module.eventhubs[0].eventhub_names, [])
}

output "worker_enabled" {
  value = try(module.container_apps[0].worker_enabled, false)
}

output "diagnostic_setting_count" {
  value = try(length(module.diagnostic_settings[0].diagnostic_setting_ids), 0)
}
