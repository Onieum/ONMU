locals {
  environment   = "staging"
  secret_prefix = "staging"
  # Runtime secret source는 기존 dev Key Vault를 재사용하고, staging 전용 vault cleanup은 별도 작업으로 분리한다.
  runtime_key_vault_name = "onmu-dev-kv-27db5e"

  tags = {
    app                 = "onmu"
    env                 = local.environment
    owner               = var.owner
    cost_center         = var.cost_center
    managed_by          = "terraform"
    data_classification = var.data_classification
  }

  # Front Door caches Blob CORS response headers per object. Public tile/static
  # assets do not use credentials, so staging keeps ACAO wildcard to avoid
  # serving one caller origin's header value to another caller from edge cache.
  tile_cors_allowed_origins = ["*"]

  resource_group_name     = var.create_resource_group ? module.resource_group[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_location = var.create_resource_group ? module.resource_group[0].location : data.azurerm_resource_group.existing[0].location
  runtime_key_vault_id    = data.azurerm_key_vault.runtime.id
  key_vault_uri           = data.azurerm_key_vault.runtime.vault_uri

  spring_secret_names = {
    DATABASE_URL                          = "${local.secret_prefix}-database-url"
    POSTGRES_PASSWORD                     = "${local.secret_prefix}-postgres-password"
    SPRING_DATASOURCE_URL                 = "${local.secret_prefix}-database-url"
    SPRING_DATASOURCE_PASSWORD            = "${local.secret_prefix}-postgres-password"
    ONMU_ACCESS_TOKEN_SECRET              = "${local.secret_prefix}-access-token-secret"
    REDIS_URL                             = "${local.secret_prefix}-redis-url"
    SPRING_DATA_REDIS_URL                 = "${local.secret_prefix}-redis-url"
    ONMU_CORS_ORIGINS                     = "${local.secret_prefix}-cors-origins"
    KAKAO_REST_API_KEY                    = "${local.secret_prefix}-kakao-rest-api-key"
    KAKAO_CLIENT_SECRET                   = "${local.secret_prefix}-kakao-client-secret"
    KAKAO_OAUTH_REDIRECT_URI              = "${local.secret_prefix}-kakao-oauth-redirect-uri"
    KAKAO_OAUTH_MOBILE_CALLBACK_URI       = "${local.secret_prefix}-kakao-oauth-mobile-callback-uri"
    NAVER_OAUTH_CLIENT_ID                 = "${local.secret_prefix}-naver-oauth-client-id"
    NAVER_OAUTH_CLIENT_SECRET             = "${local.secret_prefix}-naver-oauth-client-secret"
    NAVER_OAUTH_REDIRECT_URI              = "${local.secret_prefix}-naver-oauth-redirect-uri"
    NAVER_OAUTH_MOBILE_CALLBACK_URI       = "${local.secret_prefix}-naver-oauth-mobile-callback-uri"
    GOOGLE_OAUTH_CLIENT_ID                = "${local.secret_prefix}-google-oauth-client-id"
    GOOGLE_SERVER_CLIENT_ID               = "${local.secret_prefix}-google-server-client-id"
    NAVER_SEARCH_CLIENT_ID                = "${local.secret_prefix}-naver-search-client-id"
    NAVER_SEARCH_CLIENT_SECRET            = "${local.secret_prefix}-naver-search-client-secret"
    OPENROUTESERVICE_API_KEY              = "${local.secret_prefix}-openrouteservice-api-key"
    OBJECT_STORAGE_ENDPOINT               = "${local.secret_prefix}-blob-endpoint"
    OBJECT_STORAGE_BUCKET                 = "${local.secret_prefix}-blob-container"
    APPLICATIONINSIGHTS_CONNECTION_STRING = "${local.secret_prefix}-appinsights-connection-string"
  }

  worker_ai_secret_names = {
    ONMU_HF_TOKEN             = "${local.secret_prefix}-hf-token"
    ONMU_OOTD_MODEL_ID        = "${local.secret_prefix}-ootd-model-id"
    ONMU_OOTD_MODEL_REVISION  = "${local.secret_prefix}-ootd-model-revision"
    ONMU_AZUREML_ENDPOINT_URL = "${local.secret_prefix}-azureml-endpoint-url"
    ONMU_AZUREML_ENDPOINT_KEY = "${local.secret_prefix}-azureml-endpoint-key"
    ONMU_VISION_API_KEY       = "${local.secret_prefix}-vision-api-key"
  }

  spring_secret_refs = {
    for env_name, secret_name in local.spring_secret_names :
    lower(replace(env_name, "_", "-")) => "${local.key_vault_uri}secrets/${secret_name}"
  }

  worker_ai_secret_refs = var.ootd_generation_provider == "azure_ml" ? {
    for env_name, secret_name in local.worker_ai_secret_names :
    lower(replace(env_name, "_", "-")) => "${local.key_vault_uri}secrets/${secret_name}"
  } : {}

  spring_secret_env = {
    for env_name, secret_name in local.spring_secret_names :
    env_name => lower(replace(env_name, "_", "-"))
  }

  worker_ai_secret_env = var.ootd_generation_provider == "azure_ml" ? {
    for env_name, secret_name in local.worker_ai_secret_names :
    env_name => lower(replace(env_name, "_", "-"))
  } : {}

  worker_ai_plain_env = merge(
    {
      AZURE_CLIENT_ID               = try(module.key_vault[0].runtime_identity_client_id, "")
      ONMU_OOTD_GENERATION_PROVIDER = var.ootd_generation_provider
      ONMU_VISION_MODEL_DEPLOYMENT  = var.vision_model_deployment_name
    },
    var.enabled_modules.ai_foundation ? {
      ONMU_AZUREML_WORKSPACE_NAME = module.ai_foundation[0].machine_learning_workspace_name
      ONMU_VISION_ENDPOINT        = module.ai_foundation[0].vision_openai_endpoint
    } : {}
  )

  foundation_diagnostic_target_candidates = {
    key_vault                  = try(module.key_vault[0].key_vault_id, null)
    storage                    = try(module.storage[0].storage_account_id, null)
    cdn_profile                = try(module.cdn[0].profile_id, null)
    cdn_endpoint               = try(module.cdn[0].endpoint_id, null)
    eventhubs_namespace        = try(module.eventhubs[0].namespace_id, null)
    container_apps_environment = try(module.container_apps[0].environment_id, null)
  }

  ai_diagnostic_target_candidates = {
    machine_learning_workspace = try(module.ai_foundation[0].machine_learning_workspace_id, null)
    vision_openai_account      = try(module.ai_foundation[0].vision_openai_account_id, null)
  }

  redis_diagnostic_target_candidates = {
    redis = try(module.redis[0].id, null)
  }

  frontdoor_diagnostic_target_candidates = {
    # Azure Front Door diagnostics currently attach at the profile scope.
    # afdEndpoints do not support diagnostic settings in this subscription/runtime path.
    frontdoor_profile = try(module.front_door[0].profile_id, null)
  }

  foundation_diagnostic_targets = {
    for name, id in local.foundation_diagnostic_target_candidates :
    name => id
    if id != null && id != ""
  }

  redis_diagnostic_targets = {
    for name, id in local.redis_diagnostic_target_candidates :
    name => id
    if id != null && id != ""
  }

  frontdoor_diagnostic_targets = {
    for name, id in local.frontdoor_diagnostic_target_candidates :
    name => id
    if id != null && id != ""
  }

  ai_diagnostic_targets = {
    for name, id in local.ai_diagnostic_target_candidates :
    name => id
    if id != null && id != ""
  }

  diagnostic_targets = merge(
    var.enabled_diagnostic_targets.foundation ? local.foundation_diagnostic_targets : {},
    var.enabled_diagnostic_targets.redis ? local.redis_diagnostic_targets : {},
    var.enabled_diagnostic_targets.front_door ? local.frontdoor_diagnostic_targets : {}
  )
}

module "naming" {
  source      = "../../modules/naming"
  app_name    = "onmu"
  environment = local.environment
  region_code = var.region_code
  suffix      = var.name_suffix
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.existing_resource_group_name
}

data "azurerm_key_vault" "runtime" {
  name                = local.runtime_key_vault_name
  resource_group_name = local.resource_group_name
}

data "azurerm_container_app_environment" "existing" {
  count = var.enabled_modules.postgres && var.enabled_modules.container_apps_environment ? 1 : 0

  name                = module.naming.container_app_environment_name
  resource_group_name = local.resource_group_name
}

module "resource_group" {
  count = var.create_resource_group ? 1 : 0

  source   = "../../modules/resource-group"
  name     = module.naming.resource_group_name
  location = var.location
  tags     = local.tags
}

module "observability" {
  count = var.enabled_modules.observability ? 1 : 0

  source                       = "../../modules/observability"
  resource_group_name          = local.resource_group_name
  location                     = local.resource_group_location
  log_analytics_workspace_name = module.naming.log_analytics_workspace_name
  application_insights_name    = module.naming.application_insights_name
  log_retention_days           = 30
  tags                         = local.tags
}

module "key_vault" {
  count = var.enabled_modules.key_vault ? 1 : 0

  source                                      = "../../modules/key-vault"
  resource_group_name                         = local.resource_group_name
  location                                    = local.resource_group_location
  tenant_id                                   = var.tenant_id
  key_vault_name                              = module.naming.key_vault_name
  user_assigned_identity_name                 = module.naming.user_assigned_identity_name
  create_runtime_secrets_user_role_assignment = var.enabled_modules.rbac_assignments
  tags                                        = local.tags
}

module "container_registry" {
  count = var.enabled_modules.container_registry ? 1 : 0

  source              = "../../modules/container-registry"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  name                = module.naming.container_registry_name
  sku                 = "Basic"
  tags                = local.tags
}

module "postgres" {
  count = var.enabled_modules.postgres ? 1 : 0

  source                        = "../../modules/postgres"
  resource_group_name           = local.resource_group_name
  location                      = local.resource_group_location
  server_name                   = module.naming.postgres_server_name
  database_name                 = module.naming.postgres_database_name
  administrator_login           = var.postgres_administrator_login
  administrator_password        = var.postgres_administrator_password
  postgres_version              = "16"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  backup_retention_days         = 7
  public_network_access_enabled = true
  enabled_extensions            = ["POSTGIS", "PGCRYPTO"]
  firewall_rules = try(data.azurerm_container_app_environment.existing[0].static_ip_address, null) == null ? {} : {
    "aca-environment-static-ip" = {
      start_ip_address = data.azurerm_container_app_environment.existing[0].static_ip_address
      end_ip_address   = data.azurerm_container_app_environment.existing[0].static_ip_address
    }
  }
  tags = local.tags
}

module "redis" {
  count = var.enabled_modules.redis ? 1 : 0

  source                    = "../../modules/redis"
  resource_group_name       = local.resource_group_name
  location                  = local.resource_group_location
  name                      = module.naming.redis_name
  sku_name                  = "Balanced_B0"
  public_network_access     = "Enabled"
  high_availability_enabled = false
  default_database = {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "NoCluster"
    eviction_policy                    = "AllKeysLRU"
  }
  tags = local.tags
}

module "storage" {
  count = var.enabled_modules.storage ? 1 : 0

  source                    = "../../modules/storage"
  resource_group_name       = local.resource_group_name
  location                  = local.resource_group_location
  account_name              = module.naming.storage_account_name
  replication_type          = "LRS"
  media_container_name      = module.naming.media_container_name
  tile_container_name       = module.naming.tile_container_name
  tile_cors_allowed_origins = local.tile_cors_allowed_origins
  tags                      = local.tags
}

module "cdn" {
  count = var.enabled_modules.cdn ? 1 : 0

  source                        = "../../modules/cdn"
  resource_group_name           = local.resource_group_name
  profile_name                  = module.naming.cdn_profile_name
  endpoint_name                 = module.naming.cdn_endpoint_name
  sku                           = "Standard_Microsoft"
  origin_host_name              = module.storage[0].primary_blob_host
  querystring_caching_behaviour = "IgnoreQueryString"
  tags                          = local.tags
}

module "front_door" {
  count = var.enabled_modules.front_door ? 1 : 0

  source              = "../../modules/front-door"
  resource_group_name = local.resource_group_name
  profile_name        = module.naming.frontdoor_profile_name
  endpoint_name       = module.naming.frontdoor_endpoint_name
  origin_group_name   = module.naming.frontdoor_origin_group_name
  origin_name         = module.naming.frontdoor_origin_name
  route_name          = module.naming.frontdoor_route_name
  origin_host_name    = module.storage[0].primary_blob_host
  origin_path         = "/tiles"
  patterns_to_match   = ["/*"]
  health_probe_path   = "/"
  tags                = local.tags
}

module "eventhubs" {
  count = var.enabled_modules.eventhubs ? 1 : 0

  source              = "../../modules/eventhubs"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  namespace_name      = module.naming.eventhubs_namespace_name
  sku                 = "Standard"
  capacity            = 1
  eventhubs = {
    notification-requested = {
      partition_count   = 2
      message_retention = 1
      consumer_groups   = ["worker", "analytics"]
    }
    worker-jobs = {
      partition_count   = 2
      message_retention = 1
      consumer_groups   = ["worker", "analytics"]
    }
  }
  tags = local.tags
}

module "ai_foundation" {
  count = var.enabled_modules.ai_foundation ? 1 : 0

  source                              = "../../modules/ai-foundation"
  resource_group_name                 = local.resource_group_name
  location                            = local.resource_group_location
  machine_learning_workspace_name     = module.naming.machine_learning_workspace_name
  vision_openai_account_name          = module.naming.vision_openai_account_name
  vision_openai_custom_subdomain_name = module.naming.vision_openai_custom_subdomain_name
  vision_openai_deployment            = var.vision_openai_deployment
  application_insights_id             = module.observability[0].application_insights_id
  key_vault_id                        = local.runtime_key_vault_id
  storage_account_id                  = module.storage[0].storage_account_id
  container_registry_id               = module.container_registry[0].id
  eventhubs_namespace_id              = try(module.eventhubs[0].namespace_id, null)
  runtime_principal_id                = try(module.key_vault[0].runtime_identity_principal_id, null)
  create_runtime_role_assignments     = var.enabled_modules.rbac_assignments
  public_network_access_enabled       = true
  tags                                = local.tags
}

module "container_apps" {
  count = (var.enabled_modules.container_apps_environment || var.enabled_modules.container_apps) ? 1 : 0

  source                     = "../../modules/container-apps"
  resource_group_name        = local.resource_group_name
  location                   = local.resource_group_location
  environment_name           = module.naming.container_app_environment_name
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id
  runtime_identity_id        = module.key_vault[0].runtime_identity_id
  create_spring_api_app      = var.enabled_modules.container_apps
  tags                       = local.tags
  registry = var.enabled_modules.container_apps ? {
    server   = module.container_registry[0].login_server
    identity = module.key_vault[0].runtime_identity_id
  } : null

  spring_api = {
    name         = module.naming.spring_container_app_name
    image        = var.spring_api_image
    target_port  = 8080
    min_replicas = 1
    max_replicas = 2
    cpu          = 0.5
    memory       = "1Gi"
    plain_env = {
      AZURE_CLIENT_ID            = module.key_vault[0].runtime_identity_client_id
      OBJECT_STORAGE_PROVIDER    = "azure_blob"
      ONMU_ENV                   = local.environment
      SERVER_ADDRESS             = "0.0.0.0"
      SERVER_PORT                = "8080"
      SPRING_DATASOURCE_USERNAME = var.postgres_administrator_login
    }
    secret_env  = local.spring_secret_env
    secret_refs = local.spring_secret_refs
    startup_probe = {
      transport               = "HTTP"
      port                    = 8080
      path                    = "/healthz"
      interval_seconds        = 5
      timeout                 = 3
      failure_count_threshold = 20
    }
    liveness_probe = {
      transport               = "HTTP"
      port                    = 8080
      path                    = "/healthz"
      initial_delay           = 30
      interval_seconds        = 30
      timeout                 = 5
      failure_count_threshold = 3
    }
    readiness_probe = {
      transport               = "HTTP"
      port                    = 8080
      path                    = "/readyz"
      interval_seconds        = 10
      timeout                 = 5
      failure_count_threshold = 3
      success_count_threshold = 1
    }
  }

  worker = {
    enabled      = var.enabled_modules.container_apps && var.worker_enabled
    name         = module.naming.worker_container_app_name
    image        = var.worker_image
    target_port  = 8000
    min_replicas = 0
    max_replicas = 1
    cpu          = 0.5
    memory       = "1Gi"
    plain_env = merge(
      {
        ONMU_ENV = local.environment
      },
      local.worker_ai_plain_env
    )
    secret_env  = local.worker_ai_secret_env
    secret_refs = local.worker_ai_secret_refs
    startup_probe = {
      transport               = "HTTP"
      port                    = 8000
      path                    = "/healthz"
      interval_seconds        = 5
      timeout                 = 3
      failure_count_threshold = 12
    }
    liveness_probe = {
      transport               = "HTTP"
      port                    = 8000
      path                    = "/healthz"
      initial_delay           = 10
      interval_seconds        = 30
      timeout                 = 5
      failure_count_threshold = 3
    }
    readiness_probe = {
      transport               = "HTTP"
      port                    = 8000
      path                    = "/healthz"
      interval_seconds        = 10
      timeout                 = 5
      failure_count_threshold = 3
      success_count_threshold = 1
    }
  }

  depends_on = [
    module.key_vault
  ]
}

module "diagnostic_settings" {
  count = var.enabled_modules.diagnostics ? 1 : 0

  source                     = "../../modules/diagnostic-settings"
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id
  targets                    = local.diagnostic_targets
  name_prefix                = "diag-onmu-staging"

  depends_on = [
    module.observability,
    module.key_vault,
    module.redis,
    module.storage,
    module.cdn,
    module.front_door,
    module.eventhubs,
    module.ai_foundation,
    module.container_apps
  ]
}

module "ai_diagnostic_settings" {
  count = var.enabled_modules.diagnostics && var.enabled_diagnostic_targets.ai ? 1 : 0

  source                     = "../../modules/diagnostic-settings"
  log_analytics_workspace_id = module.observability[0].log_analytics_workspace_id
  targets                    = local.ai_diagnostic_targets
  name_prefix                = "diag-onmu-staging-ai"

  depends_on = [
    module.observability,
    module.key_vault,
    module.ai_foundation
  ]
}

module "network" {
  source  = "../../modules/network"
  enabled = false
  notes = [
    "Staging 1차는 public ingress로 시작한다.",
    "Private endpoint와 VNet은 production hardening에서 재평가한다."
  ]
}

module "edge_decision" {
  source           = "../../modules/edge"
  enabled          = true
  selected_pattern = "blob-storage-plus-front-door"
  notes = [
    "Tile/static serving은 Blob Storage + Azure Front Door Standard로 진행한다.",
    "Custom domain/TLS와 WAF 정책은 별도 승인 단계에서 붙인다."
  ]
}
