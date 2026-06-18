locals {
  raw_parts = compact([var.app_name, var.environment, var.region_code, var.suffix])
  base      = lower(join("-", local.raw_parts))
  compact   = lower(replace(join("", local.raw_parts), "/[^0-9A-Za-z]/", ""))
}

output "resource_group_name" {
  value = "rg-${local.base}"
}

output "container_app_environment_name" {
  value = "cae-${local.base}"
}

output "spring_container_app_name" {
  value = "ca-${local.base}-api"
}

output "worker_container_app_name" {
  value = "ca-${local.base}-worker"
}

output "key_vault_name" {
  value = substr("kv${local.compact}", 0, 24)
}

output "user_assigned_identity_name" {
  value = "id-${local.base}-runtime"
}

output "container_registry_name" {
  value = substr("acr${local.compact}", 0, 50)
}

output "postgres_server_name" {
  value = "psql-${local.base}"
}

output "postgres_database_name" {
  value = "onmu_${replace(var.environment, "-", "_")}"
}

output "redis_name" {
  value = "redis-${local.base}"
}

output "storage_account_name" {
  value = substr("st${local.compact}", 0, 24)
}

output "media_container_name" {
  value = "media"
}

output "tile_container_name" {
  value = "tiles"
}

output "eventhubs_namespace_name" {
  value = "evh-${local.base}"
}

output "cdn_profile_name" {
  value = "cdn-${local.base}"
}

output "cdn_endpoint_name" {
  value = substr("cdn-${local.compact}", 0, 46)
}

output "frontdoor_profile_name" {
  value = "afd-${local.base}"
}

output "frontdoor_endpoint_name" {
  value = substr("fde-${local.compact}", 0, 46)
}

output "frontdoor_origin_group_name" {
  value = "og-blob-tiles-static"
}

output "frontdoor_origin_name" {
  value = "origin-blob-tiles-static"
}

output "frontdoor_route_name" {
  value = "route-tiles-static"
}

output "log_analytics_workspace_name" {
  value = "log-${local.base}"
}

output "application_insights_name" {
  value = "appi-${local.base}"
}

output "machine_learning_workspace_name" {
  value = "mlw-${local.base}"
}

output "vision_openai_account_name" {
  value = "oai-${local.base}"
}

output "vision_openai_custom_subdomain_name" {
  value = substr("oai${local.compact}", 0, 64)
}
