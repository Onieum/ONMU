output "resource_group_name" {
  value = module.resource_group.name
}

output "spring_api_latest_revision_fqdn" {
  value = module.container_apps.spring_api_latest_revision_fqdn
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "redis_hostname" {
  value = module.redis.hostname
}

output "blob_endpoint" {
  value = module.storage.primary_blob_endpoint
}

output "cdn_endpoint_host_name" {
  value = module.cdn.endpoint_host_name
}

output "eventhub_names" {
  value = module.eventhubs.eventhub_names
}

output "worker_enabled" {
  value = module.container_apps.worker_enabled
}
