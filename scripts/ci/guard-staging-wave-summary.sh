#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <wave> <plan-json-path>" >&2
  exit 1
fi

wave="$1"
plan_json="$2"

count_by_action() {
  local action="$1"
  jq --arg action "$action" '[.resource_changes[]? | select((.change.actions | join(",")) == $action)] | length' "$plan_json"
}

count_types_by_action() {
  local action="$1"
  local type="$2"
  jq --arg action "$action" --arg type "$type" '[.resource_changes[]? | select((.change.actions | join(",")) == $action and .type == $type)] | length' "$plan_json"
}

count_addresses_by_action() {
  local action="$1"
  local address="$2"
  jq --arg action "$action" --arg address "$address" '[.resource_changes[]? | select((.change.actions | join(",")) == $action and .address == $address)] | length' "$plan_json"
}

case "$wave" in
  core_foundation)
    unexpected_mutation="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.type != "azurerm_container_app_environment" and .type != "azurerm_eventhub" and .type != "azurerm_eventhub_consumer_group" and .type != "azurerm_eventhub_namespace" and .type != "azurerm_key_vault" and .type != "azurerm_storage_account" and .type != "azurerm_storage_container" and .type != "azurerm_user_assigned_identity")) | .type] | length' "$plan_json")"
    storage_container_creates="$(count_types_by_action create azurerm_storage_container)"
    if [ "$unexpected_mutation" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only foundation create actions and existing resource no-op/read are allowed for core_foundation." >&2
      exit 1
    fi
    if [ "$storage_container_creates" -gt 0 ]; then
      echo "core_foundation still plans azurerm_storage_container create. Import the existing tiles container into staging state before retrying apply." >&2
      exit 1
    fi
    ;;
  core_diagnostics)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_monitor_diagnostic_setting") | .type] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only azurerm_monitor_diagnostic_setting create and existing resource no-op/read are allowed for core_diagnostics." >&2
      exit 1
    fi
    ;;
  managed_redis_ready)
    unexpected_mutation="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_managed_redis") | .type] | length' "$plan_json")"
    managed_redis_creates="$(count_types_by_action create azurerm_managed_redis)"
    if [ "$unexpected_mutation" -gt 0 ] || [ "$unexpected_create" -gt 0 ] || [ "$managed_redis_creates" -ne 1 ]; then
      echo "Only one azurerm_managed_redis create and existing resource no-op/read are allowed for managed_redis_ready." >&2
      exit 1
    fi
    ;;
  managed_redis_diagnostics)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_monitor_diagnostic_setting") | .type] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only azurerm_monitor_diagnostic_setting create and existing resource no-op/read are allowed for managed_redis_diagnostics." >&2
      exit 1
    fi
    ;;
  frontdoor_tile_edge)
    unexpected_mutation="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "update" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.type != "azurerm_cdn_frontdoor_profile" and .type != "azurerm_cdn_frontdoor_endpoint" and .type != "azurerm_cdn_frontdoor_origin_group" and .type != "azurerm_cdn_frontdoor_origin" and .type != "azurerm_cdn_frontdoor_route")) | .type] | length' "$plan_json")"
    unexpected_update="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "update" and .type != "azurerm_cdn_frontdoor_route") | .type] | length' "$plan_json")"
    if [ "$unexpected_mutation" -gt 0 ] || [ "$unexpected_create" -gt 0 ] || [ "$unexpected_update" -gt 0 ]; then
      echo "Only Front Door create actions or a single azurerm_cdn_frontdoor_route update, plus existing resource no-op/read, are allowed for frontdoor_tile_edge." >&2
      exit 1
    fi
    ;;
  frontdoor_origin_access)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "update" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_update="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "update" and (.type != "azurerm_storage_account" and .type != "azurerm_storage_container")) | .type] | length' "$plan_json")"
    storage_account_updates="$(count_types_by_action update azurerm_storage_account)"
    storage_container_updates="$(count_types_by_action update azurerm_storage_container)"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_update" -gt 0 ] || [ "$storage_account_updates" -ne 1 ] || [ "$storage_container_updates" -gt 1 ]; then
      echo "Only one azurerm_storage_account update and zero or one azurerm_storage_container update are allowed for frontdoor_origin_access. Existing Front Door and diagnostics must stay no-op/read." >&2
      exit 1
    fi
    ;;
  frontdoor_diagnostics)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_monitor_diagnostic_setting") | .type] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only supported Front Door diagnostic setting create and existing resource no-op/read are allowed for frontdoor_diagnostics." >&2
      exit 1
    fi
    ;;
  postgres_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.type != "azurerm_postgresql_flexible_server" and .type != "azurerm_postgresql_flexible_server_configuration" and .type != "azurerm_postgresql_flexible_server_database" and .type != "azurerm_postgresql_flexible_server_firewall_rule")) | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only PostgreSQL server, extension configuration, database, and firewall rule create plus existing resource no-op/read are allowed for postgres_ready." >&2
      exit 1
    fi
    ;;
  postgres_firewall_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_postgresql_flexible_server_firewall_rule") | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only PostgreSQL firewall rule create plus existing resource no-op/read are allowed for postgres_firewall_ready." >&2
      exit 1
    fi
    ;;
  api_app_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .address != "module.container_apps[0].azurerm_container_app.spring_api[0]") | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only Spring API container app create plus existing resource no-op/read are allowed for api_app_ready." >&2
      exit 1
    fi
    ;;
  worker_app_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .address != "module.container_apps[0].azurerm_container_app.worker[0]") | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only worker container app create plus existing resource no-op/read are allowed for worker_app_ready." >&2
      exit 1
    fi
    ;;
  place_reason_worker_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "update" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.address != "module.container_apps[0].azurerm_container_app.spring_api[0]" and .address != "module.container_apps[0].azurerm_container_app.worker[0]")) | .address] | length' "$plan_json")"
    unexpected_update="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "update" and (.address != "module.container_apps[0].azurerm_container_app.spring_api[0]" and .address != "module.container_apps[0].azurerm_container_app.worker[0]")) | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ] || [ "$unexpected_update" -gt 0 ]; then
      echo "Only Spring API and worker container app create/update plus existing resource no-op/read are allowed for place_reason_worker_ready." >&2
      exit 1
    fi
    ;;
  worker_ai_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "update" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .address != "module.container_apps[0].azurerm_container_app.worker[0]") | .address] | length' "$plan_json")"
    unexpected_update="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "update" and .address != "module.container_apps[0].azurerm_container_app.worker[0]") | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ] || [ "$unexpected_update" -gt 0 ]; then
      echo "Only worker container app create/update plus existing resource no-op/read are allowed for worker_ai_ready." >&2
      exit 1
    fi
    ;;
  ai_foundation)
    unexpected_mutation="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.type != "azurerm_machine_learning_workspace" and .type != "azurerm_cognitive_account" and .type != "azurerm_cognitive_deployment")) | .address] | length' "$plan_json")"
    ml_workspace_creates="$(count_types_by_action create azurerm_machine_learning_workspace)"
    cognitive_account_creates="$(count_types_by_action create azurerm_cognitive_account)"
    if [ "$unexpected_mutation" -gt 0 ] || [ "$unexpected_create" -gt 0 ] || [ "$ml_workspace_creates" -ne 1 ] || [ "$cognitive_account_creates" -ne 1 ]; then
      echo "Only AI foundation creates and existing resource no-op/read are allowed for ai_foundation. Run ai_diagnostics after foundation resources are in state." >&2
      exit 1
    fi
    ;;
  ai_diagnostics)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .type] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and .type != "azurerm_monitor_diagnostic_setting") | .type] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only AI diagnostic setting create and existing resource no-op/read are allowed for ai_diagnostics." >&2
      exit 1
    fi
    ;;
  db_and_app_ready)
    unexpected="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) != "no-op" and (.change.actions | join(",")) != "create" and (.change.actions | join(",")) != "read") | .address] | length' "$plan_json")"
    unexpected_create="$(jq '[.resource_changes[]? | select((.change.actions | join(",")) == "create" and (.address != "module.postgres[0].azurerm_postgresql_flexible_server.this" and .address != "module.postgres[0].azurerm_postgresql_flexible_server_configuration.extensions[0]" and .address != "module.postgres[0].azurerm_postgresql_flexible_server_database.this" and .address != "module.container_apps[0].azurerm_container_app.spring_api[0]" and .address != "module.container_apps[0].azurerm_container_app.worker[0]")) | .address] | length' "$plan_json")"
    if [ "$unexpected" -gt 0 ] || [ "$unexpected_create" -gt 0 ]; then
      echo "Only PostgreSQL and container app creates plus existing resource no-op/read are allowed for db_and_app_ready." >&2
      exit 1
    fi
    ;;
esac
