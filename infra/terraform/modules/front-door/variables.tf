variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "profile_name" {
  description = "Azure Front Door profile name."
  type        = string
}

variable "endpoint_name" {
  description = "Azure Front Door endpoint name."
  type        = string
}

variable "origin_group_name" {
  description = "Origin group name."
  type        = string
}

variable "origin_name" {
  description = "Blob origin name."
  type        = string
}

variable "route_name" {
  description = "Route name for tile/static delivery."
  type        = string
}

variable "origin_host_name" {
  description = "Blob origin host name without scheme."
  type        = string
}

variable "patterns_to_match" {
  description = "Route path patterns."
  type        = list(string)
  default     = ["/*"]
}

variable "health_probe_path" {
  description = "Origin health probe path. Keep generic until tile manifest path is finalized."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
