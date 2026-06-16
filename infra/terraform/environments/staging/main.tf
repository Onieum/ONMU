locals {
  environment   = "staging"
  secret_prefix = "staging"

  tags = {
    app                 = "onmu"
    env                 = local.environment
    owner               = var.owner
    cost_center         = var.cost_center
    managed_by          = "terraform"
    data_classification = var.data_classification
  }

  spring_secret_names = {
    DATABASE_URL                          = "${local.secret_prefix}-database-url"
    POSTGRES_PASSWORD                     = "${local.secret_prefix}-postgres-password"
    ONMU_ACCESS_TOKEN_SECRET              = "${local.secret_prefix}-access-token-secret"
    REDIS_URL                             = "${local.secret_prefix}-redis-url"
    SPRING_DATA_REDIS_URL                 = "${local.secret_prefix}-redis-url"
    ONMU_CORS_ORIGINS                     = "${local.secret_prefix}-cors-origins"
    KAKAO_REST_API_KEY                    = "${local.secret_prefix}-kakao-rest-api-key"
    KAKAO_CLIENT_SECRET                   = "${local.secret_prefix}-kakao-client-secret"
    NAVER_OAUTH_CLIENT_ID                 = "${local.secret_prefix}-naver-oauth-client-id"
    NAVER_OAUTH_CLIENT_SECRET             = "${local.secret_prefix}-naver-oauth-client-secret"
    GOOGLE_OAUTH_CLIENT_ID                = "${local.secret_prefix}-google-oauth-client-id"
    GOOGLE_SERVER_CLIENT_ID               = "${local.secret_prefix}-google-server-client-id"
    NAVER_SEARCH_CLIENT_ID                = "${local.secret_prefix}-naver-search-client-id"
    NAVER_SEARCH_CLIENT_SECRET            = "${local.secret_prefix}-naver-search-client-secret"
    OPENROUTESERVICE_API_KEY              = "${local.secret_prefix}-openrouteservice-api-key"
    OBJECT_STORAGE_ENDPOINT               = "${local.secret_prefix}-blob-endpoint"
    OBJECT_STORAGE_BUCKET                 = "${local.secret_prefix}-blob-container"
    APPLICATIONINSIGHTS_CONNECTION_STRING = "${local.secret_prefix}-appinsights-connection-string"
  }

  spring_secret_refs = {
    for env_name, secret_name in local.spring_secret_names :
    lower(replace(env_name, "_", "-")) => "${module.key_vault.key_vault_uri}secrets/${secret_name}"
  }

  spring_secret_env = {
    for env_name, secret_name in local.spring_secret_names :
    env_name => lower(replace(env_name, "_", "-"))
  }
}

module "naming" {
  source      = "../../modules/naming"
  app_name    = "onmu"
  environment = local.environment
  region_code = var.region_code
  suffix      = var.name_suffix
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = module.naming.resource_group_name
  location = var.location
  tags     = local.tags
}

module "observability" {
  source                       = "../../modules/observability"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  log_analytics_workspace_name = module.naming.log_analytics_workspace_name
  application_insights_name    = module.naming.application_insights_name
  log_retention_days           = 30
  tags                         = local.tags
}

module "key_vault" {
  source                      = "../../modules/key-vault"
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  tenant_id                   = var.tenant_id
  key_vault_name              = module.naming.key_vault_name
  user_assigned_identity_name = module.naming.user_assigned_identity_name
  tags                        = local.tags
}

module "container_registry" {
  source              = "../../modules/container-registry"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = module.naming.container_registry_name
  sku                 = "Basic"
  tags                = local.tags
}

module "postgres" {
  source                        = "../../modules/postgres"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  server_name                   = module.naming.postgres_server_name
  database_name                 = module.naming.postgres_database_name
  administrator_login           = var.postgres_administrator_login
  administrator_password        = var.postgres_administrator_password
  postgres_version              = "16"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  backup_retention_days         = 7
  public_network_access_enabled = true
  enabled_extensions            = ["POSTGIS"]
  tags                          = local.tags
}

module "redis" {
  source              = "../../modules/redis"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = module.naming.redis_name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  minimum_tls_version = "1.2"
  tags                = local.tags
}

module "storage" {
  source               = "../../modules/storage"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  account_name         = module.naming.storage_account_name
  replication_type     = "LRS"
  media_container_name = module.naming.media_container_name
  tile_container_name  = module.naming.tile_container_name
  tags                 = local.tags
}

module "cdn" {
  source                        = "../../modules/cdn"
  resource_group_name           = module.resource_group.name
  profile_name                  = module.naming.cdn_profile_name
  endpoint_name                 = module.naming.cdn_endpoint_name
  sku                           = "Standard_Microsoft"
  origin_host_name              = module.storage.primary_blob_host
  querystring_caching_behaviour = "IgnoreQueryString"
  tags                          = local.tags
}

module "eventhubs" {
  source              = "../../modules/eventhubs"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
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

module "container_apps" {
  source                     = "../../modules/container-apps"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  environment_name           = module.naming.container_app_environment_name
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  runtime_identity_id        = module.key_vault.runtime_identity_id
  tags                       = local.tags

  spring_api = {
    name         = module.naming.spring_container_app_name
    image        = var.spring_api_image
    target_port  = 8080
    min_replicas = 1
    max_replicas = 2
    cpu          = 0.5
    memory       = "1Gi"
    plain_env = {
      ONMU_ENV       = local.environment
      SERVER_ADDRESS = "0.0.0.0"
      SERVER_PORT    = "8080"
    }
    secret_env  = local.spring_secret_env
    secret_refs = local.spring_secret_refs
  }

  worker = {
    enabled      = var.worker_enabled
    name         = module.naming.worker_container_app_name
    image        = var.worker_image
    target_port  = 8000
    min_replicas = 0
    max_replicas = 1
    cpu          = 0.5
    memory       = "1Gi"
    plain_env = {
      ONMU_ENV = local.environment
    }
    secret_env  = {}
    secret_refs = {}
  }

  depends_on = [
    module.key_vault
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
  selected_pattern = "blob-storage-plus-azure-cdn"
  notes = [
    "Tile/static serving은 Blob Storage + Azure CDN으로 진행한다.",
    "Front Door/WAF는 production hardening 후보로 남긴다."
  ]
}
