variable "enabled" {
  description = "Whether edge resources are enabled in this phase."
  type        = bool
  default     = false
}

variable "selected_pattern" {
  description = "Selected edge pattern. Keep destructive DNS or gateway changes disabled until approved."
  type        = string
  default     = "blob-storage-plus-azure-cdn"
}

variable "notes" {
  description = "Decision notes for tile/API edge routing."
  type        = list(string)
  default     = []
}
