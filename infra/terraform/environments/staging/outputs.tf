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

output "container_registry_id" {
  value = try(module.container_registry[0].id, null)
}

output "key_vault_id" {
  value = local.runtime_key_vault_id
}

output "managed_key_vault_id" {
  value = try(module.key_vault[0].key_vault_id, null)
}

output "runtime_identity_id" {
  value = try(module.key_vault[0].runtime_identity_id, null)
}

output "runtime_identity_principal_id" {
  value = try(module.key_vault[0].runtime_identity_principal_id, null)
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

output "redis_port" {
  value = try(module.redis[0].port, null)
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
  value = (
    try(length(module.diagnostic_settings[0].diagnostic_setting_ids), 0) +
    try(length(module.ai_diagnostic_settings[0].diagnostic_setting_ids), 0)
  )
}

output "machine_learning_workspace_name" {
  value = try(module.ai_foundation[0].machine_learning_workspace_name, null)
}

output "machine_learning_workspace_id" {
  value = try(module.ai_foundation[0].machine_learning_workspace_id, null)
}

output "vision_openai_account_name" {
  value = try(module.ai_foundation[0].vision_openai_account_name, null)
}

output "vision_openai_endpoint" {
  value = try(module.ai_foundation[0].vision_openai_endpoint, null)
}

output "vision_openai_deployment_name" {
  value = try(module.ai_foundation[0].vision_openai_deployment_name, null)
}
