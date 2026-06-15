variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "application_insights_name" {
  description = "Application Insights name."
  type        = string
}

variable "log_retention_days" {
  description = "Log retention days for staging/prod."
  type        = number
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
