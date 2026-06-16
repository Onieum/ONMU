variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id that receives diagnostic logs and metrics."
  type        = string
}

variable "targets" {
  description = "Map of short target names to Azure resource ids."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Diagnostic setting name prefix."
  type        = string
  default     = "diag"
}
