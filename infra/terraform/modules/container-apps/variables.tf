variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "environment_name" {
  description = "Container Apps Environment name."
  type        = string
}

variable "environment_workload_profile" {
  description = "Container Apps Environment workload profile. Keep the default Consumption profile pinned so later diagnostics waves stay no-op for the environment resource."
  type = object({
    name                  = string
    workload_profile_type = string
    minimum_count         = number
    maximum_count         = number
  })
  default = {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 0
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
}

variable "runtime_identity_id" {
  description = "User-assigned managed identity id used by Container Apps to read Key Vault references."
  type        = string
}

variable "registry" {
  description = "Optional private registry binding for Container Apps image pull."
  type = object({
    server   = string
    identity = string
  })
  default  = null
  nullable = true
}

variable "create_spring_api_app" {
  description = "Create the Spring API Container App. Keep false for environment-only foundation waves."
  type        = bool
  default     = true
}

variable "spring_api" {
  description = "Spring Main API container app settings."
  type = object({
    name         = string
    image        = string
    target_port  = number
    min_replicas = number
    max_replicas = number
    cpu          = number
    memory       = string
    plain_env    = map(string)
    secret_env   = map(string)
    secret_refs  = map(string)
    startup_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
    }))
    liveness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
    }))
    readiness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
      success_count_threshold = optional(number)
    }))
  })
}

variable "worker" {
  description = "Optional FastAPI Worker container app settings."
  type = object({
    enabled      = bool
    name         = string
    image        = string
    target_port  = number
    min_replicas = number
    max_replicas = number
    cpu          = number
    memory       = string
    plain_env    = map(string)
    secret_env   = map(string)
    secret_refs  = map(string)
    startup_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
    }))
    liveness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
    }))
    readiness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
      success_count_threshold = optional(number)
    }))
  })
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
