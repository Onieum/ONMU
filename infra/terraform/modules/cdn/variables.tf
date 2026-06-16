variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "profile_name" {
  description = "Azure CDN profile name."
  type        = string
}

variable "endpoint_name" {
  description = "Azure CDN endpoint name."
  type        = string
}

variable "sku" {
  description = "Azure CDN SKU."
  type        = string
}

variable "origin_host_name" {
  description = "Blob origin host name without protocol."
  type        = string
}

variable "querystring_caching_behaviour" {
  description = "CDN query string caching behavior."
  type        = string
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
