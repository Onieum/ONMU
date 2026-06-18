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
    ai_foundation              = bool
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
    ai_foundation              = false
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
    condition     = !var.enabled_modules.container_apps || (var.enabled_modules.container_registry && var.enabled_modules.postgres)
    error_message = "enabled_modules.container_apps requires enabled_modules.container_registry and enabled_modules.postgres."
  }

  validation {
    condition     = !var.enabled_modules.ai_foundation || (var.enabled_modules.observability && var.enabled_modules.storage && var.enabled_modules.container_registry)
    error_message = "enabled_modules.ai_foundation requires enabled_modules.observability, enabled_modules.storage, and enabled_modules.container_registry."
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

variable "enabled_diagnostic_targets" {
  description = "Diagnostic target groups to keep or add by wave. Keep foundation diagnostics enabled in later waves so previously applied settings are not planned for deletion."
  type = object({
    foundation = bool
    redis      = bool
    front_door = bool
    ai         = bool
  })
  default = {
    foundation = false
    redis      = false
    front_door = false
    ai         = false
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

variable "ootd_generation_provider" {
  description = "Worker OOTD generation provider. Use mock before Azure ML endpoint smoke is ready."
  type        = string
  default     = "mock"

  validation {
    condition     = contains(["mock", "azure_ml"], var.ootd_generation_provider)
    error_message = "ootd_generation_provider must be mock or azure_ml."
  }
}

variable "vision_model_deployment_name" {
  description = "Azure OpenAI vision model deployment name used by the worker outfit descriptor step."
  type        = string
  default     = "onmu-ootd-vision"
}

variable "vision_openai_deployment" {
  description = "Optional Azure OpenAI deployment for the vision outfit descriptor. Keep null until quota/model availability is confirmed."
  type = object({
    name          = string
    model_name    = string
    model_version = string
    sku_name      = string
    capacity      = number
  })
  default  = null
  nullable = true
}
