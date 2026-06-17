resource "azurerm_container_app_environment" "this" {
  name                       = var.environment_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags

  workload_profile {
    name                  = var.environment_workload_profile.name
    workload_profile_type = var.environment_workload_profile.workload_profile_type
    minimum_count         = var.environment_workload_profile.minimum_count
    maximum_count         = var.environment_workload_profile.maximum_count
  }
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

  dynamic "registry" {
    for_each = var.registry == null ? [] : [var.registry]
    content {
      server   = registry.value.server
      identity = registry.value.identity
    }
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

      dynamic "startup_probe" {
        for_each = try(var.spring_api.startup_probe, null) == null ? [] : [var.spring_api.startup_probe]
        content {
          transport               = startup_probe.value.transport
          port                    = startup_probe.value.port
          path                    = try(startup_probe.value.path, null)
          initial_delay           = try(startup_probe.value.initial_delay, null)
          interval_seconds        = try(startup_probe.value.interval_seconds, null)
          timeout                 = try(startup_probe.value.timeout, null)
          failure_count_threshold = try(startup_probe.value.failure_count_threshold, null)
        }
      }

      dynamic "liveness_probe" {
        for_each = try(var.spring_api.liveness_probe, null) == null ? [] : [var.spring_api.liveness_probe]
        content {
          transport               = liveness_probe.value.transport
          port                    = liveness_probe.value.port
          path                    = try(liveness_probe.value.path, null)
          initial_delay           = try(liveness_probe.value.initial_delay, null)
          interval_seconds        = try(liveness_probe.value.interval_seconds, null)
          timeout                 = try(liveness_probe.value.timeout, null)
          failure_count_threshold = try(liveness_probe.value.failure_count_threshold, null)
        }
      }

      dynamic "readiness_probe" {
        for_each = try(var.spring_api.readiness_probe, null) == null ? [] : [var.spring_api.readiness_probe]
        content {
          transport               = readiness_probe.value.transport
          port                    = readiness_probe.value.port
          path                    = try(readiness_probe.value.path, null)
          interval_seconds        = try(readiness_probe.value.interval_seconds, null)
          timeout                 = try(readiness_probe.value.timeout, null)
          failure_count_threshold = try(readiness_probe.value.failure_count_threshold, null)
          success_count_threshold = try(readiness_probe.value.success_count_threshold, null)
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

  dynamic "registry" {
    for_each = var.registry == null ? [] : [var.registry]
    content {
      server   = registry.value.server
      identity = registry.value.identity
    }
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

      dynamic "startup_probe" {
        for_each = try(var.worker.startup_probe, null) == null ? [] : [var.worker.startup_probe]
        content {
          transport               = startup_probe.value.transport
          port                    = startup_probe.value.port
          path                    = try(startup_probe.value.path, null)
          initial_delay           = try(startup_probe.value.initial_delay, null)
          interval_seconds        = try(startup_probe.value.interval_seconds, null)
          timeout                 = try(startup_probe.value.timeout, null)
          failure_count_threshold = try(startup_probe.value.failure_count_threshold, null)
        }
      }

      dynamic "liveness_probe" {
        for_each = try(var.worker.liveness_probe, null) == null ? [] : [var.worker.liveness_probe]
        content {
          transport               = liveness_probe.value.transport
          port                    = liveness_probe.value.port
          path                    = try(liveness_probe.value.path, null)
          initial_delay           = try(liveness_probe.value.initial_delay, null)
          interval_seconds        = try(liveness_probe.value.interval_seconds, null)
          timeout                 = try(liveness_probe.value.timeout, null)
          failure_count_threshold = try(liveness_probe.value.failure_count_threshold, null)
        }
      }

      dynamic "readiness_probe" {
        for_each = try(var.worker.readiness_probe, null) == null ? [] : [var.worker.readiness_probe]
        content {
          transport               = readiness_probe.value.transport
          port                    = readiness_probe.value.port
          path                    = try(readiness_probe.value.path, null)
          interval_seconds        = try(readiness_probe.value.interval_seconds, null)
          timeout                 = try(readiness_probe.value.timeout, null)
          failure_count_threshold = try(readiness_probe.value.failure_count_threshold, null)
          success_count_threshold = try(readiness_probe.value.success_count_threshold, null)
        }
      }
    }
  }

  depends_on = [
    azurerm_container_app_environment.this
  ]
}
