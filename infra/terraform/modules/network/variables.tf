variable "enabled" {
  description = "Whether private networking is enabled in this phase."
  type        = bool
  default     = false
}

variable "notes" {
  description = "Decision notes for VNet, subnet, private endpoint, and DNS zone introduction."
  type        = list(string)
  default     = []
}
