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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
}

variable "runtime_identity_id" {
  description = "User-assigned managed identity id used by Container Apps to read Key Vault references."
  type        = string
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
  })
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
