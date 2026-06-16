resource "azurerm_container_app_environment" "this" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

resource "azurerm_container_app" "spring_api" {
  count                        = var.create_spring_api_app ? 1 : 0
  name                         = var.spring_api.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.runtime_identity_id]
  }

  dynamic "secret" {
    for_each = var.spring_api.secret_refs
    content {
      name                = secret.key
      key_vault_secret_id = secret.value
      identity            = var.runtime_identity_id
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.spring_api.target_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = var.spring_api.min_replicas
    max_replicas = var.spring_api.max_replicas

    container {
      name   = "spring-api"
      image  = var.spring_api.image
      cpu    = var.spring_api.cpu
      memory = var.spring_api.memory

      dynamic "env" {
        for_each = var.spring_api.plain_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.spring_api.secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }
  }

  depends_on = [
    azurerm_container_app_environment.this
  ]
}

resource "azurerm_container_app" "worker" {
  count                        = var.worker.enabled && var.create_spring_api_app ? 1 : 0
  name                         = var.worker.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.runtime_identity_id]
  }

  dynamic "secret" {
    for_each = var.worker.secret_refs
    content {
      name                = secret.key
      key_vault_secret_id = secret.value
      identity            = var.runtime_identity_id
    }
  }

  template {
    min_replicas = var.worker.min_replicas
    max_replicas = var.worker.max_replicas

    container {
      name   = "worker"
      image  = var.worker.image
      cpu    = var.worker.cpu
      memory = var.worker.memory

      dynamic "env" {
        for_each = var.worker.plain_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.worker.secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }
  }

  depends_on = [
    azurerm_container_app_environment.this
  ]
}
