variable "app_name" {
  description = "Application name used in Azure resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as staging or prod."
  type        = string
}

variable "region_code" {
  description = "Short region code used in resource names."
  type        = string
}

variable "suffix" {
  description = "Optional stable suffix for uniqueness."
  type        = string
  default     = ""
}
