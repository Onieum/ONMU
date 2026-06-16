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

variable "postgres_administrator_login" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "onmuadmin"
}

variable "postgres_administrator_password" {
  description = "PostgreSQL administrator password. Supply outside git only."
  type        = string
  sensitive   = true
}

variable "spring_api_image" {
  description = "Spring API container image digest or tag."
  type        = string
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
