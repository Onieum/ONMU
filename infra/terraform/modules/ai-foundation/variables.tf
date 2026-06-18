variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "machine_learning_workspace_name" {
  description = "Azure ML workspace name for OOTD generation model hosting."
  type        = string
}

variable "vision_openai_account_name" {
  description = "Azure OpenAI account name used by the vision outfit descriptor step."
  type        = string
}

variable "vision_openai_custom_subdomain_name" {
  description = "Custom subdomain for the Azure OpenAI account."
  type        = string
}

variable "vision_openai_sku_name" {
  description = "Azure OpenAI account SKU."
  type        = string
  default     = "S0"
}

variable "vision_openai_deployment" {
  description = "Optional Azure OpenAI vision-capable model deployment. Keep null until quota/model availability is confirmed."
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

variable "application_insights_id" {
  description = "Application Insights resource id attached to Azure ML workspace."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource id attached to Azure ML workspace."
  type        = string
}

variable "storage_account_id" {
  description = "Storage account resource id attached to Azure ML workspace and used for OOTD media."
  type        = string
}

variable "container_registry_id" {
  description = "Container Registry resource id used by Azure ML workspace."
  type        = string
  default     = null
  nullable    = true
}

variable "eventhubs_namespace_id" {
  description = "Optional Event Hubs namespace id used by worker job consumption."
  type        = string
  default     = null
  nullable    = true
}

variable "runtime_principal_id" {
  description = "Runtime managed identity principal id for worker/Spring access."
  type        = string
  default     = null
  nullable    = true
}

variable "create_runtime_role_assignments" {
  description = "Create runtime RBAC assignments for storage, Event Hubs, Azure OpenAI, and Azure ML."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access during staging. Production hardening can move this behind private networking."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
