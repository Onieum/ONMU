#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <wave> <output-path>" >&2
  exit 1
fi

wave="$1"
output_path="$2"

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "missing required environment variable: $name" >&2
    exit 1
  fi
}

write_base() {
  cat > "$output_path" <<'EOF'
location      = "koreacentral"
region_code   = "krc"
name_suffix   = "001"
owner         = "onmu-team"
cost_center   = "onmu-staging"

create_resource_group        = false
existing_resource_group_name = "3dt-final-team1"
EOF
}

append_placeholder_images() {
  cat >> "$output_path" <<'EOF'

spring_api_image = "ghcr.io/onieum/onmu-api-spring:staging-placeholder"
worker_enabled   = false
EOF
}

append_frontdoor_keepalive_targets() {
  cat >> "$output_path" <<'EOF'

enabled_diagnostic_targets = {
  foundation = true
  redis      = true
  front_door = true
}
EOF
}

write_base

case "$wave" in
  acr_observability)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = false
  postgres                   = false
  redis                      = false
  storage                    = false
  cdn                        = false
  front_door                 = false
  eventhubs                  = false
  container_apps_environment = false
  container_apps             = false
  diagnostics                = false
  rbac_assignments           = false
}
EOF
    ;;
  core_foundation)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = false
  storage                    = true
  cdn                        = false
  front_door                 = false
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = false
  rbac_assignments           = false
}
EOF
    ;;
  key_vault_rbac)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = false
  container_registry         = false
  key_vault                  = true
  postgres                   = false
  redis                      = false
  storage                    = false
  cdn                        = false
  front_door                 = false
  eventhubs                  = false
  container_apps_environment = false
  container_apps             = false
  diagnostics                = false
  rbac_assignments           = true
}
EOF
    ;;
  core_diagnostics)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = false
  storage                    = true
  cdn                        = false
  front_door                 = false
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}

enabled_diagnostic_targets = {
  foundation = true
  redis      = false
  front_door = false
}
EOF
    ;;
  managed_redis_ready)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = false
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = false
  rbac_assignments           = false
}
EOF
    ;;
  managed_redis_diagnostics)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = false
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}

enabled_diagnostic_targets = {
  foundation = true
  redis      = true
  front_door = false
}
EOF
    ;;
  frontdoor_tile_edge)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}

enabled_diagnostic_targets = {
  foundation = true
  redis      = true
  front_door = false
}
EOF
    ;;
  frontdoor_origin_access)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}

enabled_diagnostic_targets = {
  foundation = true
  redis      = true
  front_door = true
}
EOF
    ;;
  frontdoor_diagnostics)
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = false
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}

enabled_diagnostic_targets = {
  foundation = true
  redis      = true
  front_door = true
}
EOF
    ;;
  postgres_ready)
    require_env "STAGING_POSTGRES_ADMINISTRATOR_PASSWORD"
    append_placeholder_images
    cat >> "$output_path" <<'EOF'

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = true
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = false
  diagnostics                = true
  rbac_assignments           = false
}
EOF
    append_frontdoor_keepalive_targets
    ;;
  api_app_ready)
    require_env "STAGING_POSTGRES_ADMINISTRATOR_PASSWORD"
    require_env "STAGING_SPRING_API_IMAGE"
    cat >> "$output_path" <<EOF

spring_api_image = "${STAGING_SPRING_API_IMAGE}"
worker_enabled   = false

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = true
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = true
  diagnostics                = true
  rbac_assignments           = false
}
EOF
    append_frontdoor_keepalive_targets
    ;;
  worker_app_ready)
    require_env "STAGING_POSTGRES_ADMINISTRATOR_PASSWORD"
    require_env "STAGING_SPRING_API_IMAGE"
    require_env "STAGING_WORKER_IMAGE"
    cat >> "$output_path" <<EOF

spring_api_image = "${STAGING_SPRING_API_IMAGE}"
worker_image     = "${STAGING_WORKER_IMAGE}"
worker_enabled   = true

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = true
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = true
  diagnostics                = true
  rbac_assignments           = false
}
EOF
    append_frontdoor_keepalive_targets
    ;;
  db_and_app_ready)
    require_env "STAGING_POSTGRES_ADMINISTRATOR_PASSWORD"
    require_env "STAGING_SPRING_API_IMAGE"
    require_env "STAGING_WORKER_IMAGE"
    cat >> "$output_path" <<EOF

spring_api_image = "${STAGING_SPRING_API_IMAGE}"
worker_image     = "${STAGING_WORKER_IMAGE}"
worker_enabled   = true

enabled_modules = {
  observability              = true
  container_registry         = true
  key_vault                  = true
  postgres                   = true
  redis                      = true
  storage                    = true
  cdn                        = false
  front_door                 = true
  eventhubs                  = true
  container_apps_environment = true
  container_apps             = true
  diagnostics                = true
  rbac_assignments           = false
}
EOF
    append_frontdoor_keepalive_targets
    ;;
  *)
    echo "unsupported wave: $wave" >&2
    exit 1
    ;;
esac
