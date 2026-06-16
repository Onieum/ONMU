variable "tenant_id" {
  description = "Azure tenant id."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription id for provider auth when used by CI or local plan."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "koreacentral"
}

variable "region_code" {
  description = "Short region code for names."
  type        = string
  default     = "krc"
}

variable "name_suffix" {
  description = "Stable suffix for globally unique names."
  type        = string
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
}

variable "data_classification" {
  description = "Data classification tag."
  type        = string
  default     = "internal"
}

variable "create_resource_group" {
  description = "Create a dedicated staging resource group. Keep false while using the shared 3dt-final-team1 resource group."
  type        = bool
  default     = false
}

variable "existing_resource_group_name" {
  description = "Existing resource group to reuse when create_resource_group is false."
  type        = string
  default     = "3dt-final-team1"
}

variable "enabled_modules" {
  description = "Feature flags for staging infra waves. Wave 1 enables ACR and observability. Core foundation enables shared dependencies without app containers."
  type = object({
    observability              = bool
    container_registry         = bool
    key_vault                  = bool
    postgres                   = bool
    redis                      = bool
    storage                    = bool
    cdn                        = bool
    front_door                 = bool
    eventhubs                  = bool
    container_apps_environment = bool
    container_apps             = bool
    diagnostics                = bool
    rbac_assignments           = bool
  })
  default = {
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

  validation {
    condition     = !var.enabled_modules.cdn || var.enabled_modules.storage
    error_message = "enabled_modules.cdn requires enabled_modules.storage."
  }

  validation {
    condition     = !var.enabled_modules.front_door || var.enabled_modules.storage
    error_message = "enabled_modules.front_door requires enabled_modules.storage."
  }

  validation {
    condition     = !var.enabled_modules.container_apps_environment || (var.enabled_modules.key_vault && var.enabled_modules.observability)
    error_message = "enabled_modules.container_apps_environment requires enabled_modules.key_vault and enabled_modules.observability."
  }

  validation {
    condition     = !var.enabled_modules.container_apps || var.enabled_modules.container_apps_environment
    error_message = "enabled_modules.container_apps requires enabled_modules.container_apps_environment."
  }

  validation {
    condition     = !var.enabled_modules.diagnostics || var.enabled_modules.observability
    error_message = "enabled_modules.diagnostics requires enabled_modules.observability."
  }

  validation {
    condition     = !var.enabled_modules.rbac_assignments || var.enabled_modules.key_vault
    error_message = "enabled_modules.rbac_assignments requires enabled_modules.key_vault."
  }

}

variable "postgres_administrator_login" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "onmuadmin"
}

variable "postgres_administrator_password" {
  description = "PostgreSQL administrator password. Required only when enabled_modules.postgres is true. Supply outside git only."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "spring_api_image" {
  description = "Spring API container image digest or tag."
  type        = string
  default     = "ghcr.io/onieum/onmu-api-spring:staging-placeholder"
}

variable "worker_image" {
  description = "Worker container image digest or tag."
  type        = string
  default     = "ghcr.io/onieum/onmu-worker:placeholder"
}

variable "worker_enabled" {
  description = "Enable FastAPI Worker Container App."
  type        = bool
  default     = false
}
