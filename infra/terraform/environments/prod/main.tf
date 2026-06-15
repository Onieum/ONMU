locals {
  environment   = "prod"
  secret_prefix = "prod"

  # Production 값은 hardening 후보 placeholder다.
  # 별도 production approval, 비용 산출, DNS/cutover gate 전에는 apply하지 않는다.

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
  log_retention_days           = 90
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
  sku                 = "Standard"
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
  sku_name                      = "GP_Standard_D2s_v3"
  storage_mb                    = 65536
  backup_retention_days         = 14
  public_network_access_enabled = false
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
  sku_name            = "Standard"
  minimum_tls_version = "1.2"
  tags                = local.tags
}

module "storage" {
  source               = "../../modules/storage"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  account_name         = module.naming.storage_account_name
  replication_type     = "ZRS"
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
  capacity            = 2
  eventhubs = {
    notification-requested = {
      partition_count   = 4
      message_retention = 3
      consumer_groups   = ["spring-api", "notification-worker"]
    }
    worker-jobs = {
      partition_count   = 4
      message_retention = 3
      consumer_groups   = ["worker"]
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
    min_replicas = 2
    max_replicas = 5
    cpu          = 1
    memory       = "2Gi"
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
    max_replicas = 3
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
  enabled = true
  notes = [
    "Production은 private endpoint/VNet 도입을 기본 후보로 둔다.",
    "구체 subnet, DNS zone, NAT 구성은 production plan gate에서 확정한다."
  ]
}

module "edge_decision" {
  source           = "../../modules/edge"
  enabled          = true
  selected_pattern = "blob-storage-plus-azure-cdn"
  notes = [
    "Tile/static serving은 Blob Storage + Azure CDN으로 진행한다.",
    "WAF/API policy는 Front Door 또는 APIM을 production hardening 후보로 별도 검토한다."
  ]
}
