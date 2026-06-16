variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name" {
  description = "Azure Cache for Redis name."
  type        = string
}

variable "capacity" {
  description = "Redis capacity."
  type        = number
}

variable "family" {
  description = "Redis family."
  type        = string
}

variable "sku_name" {
  description = "Redis SKU name."
  type        = string
}

variable "minimum_tls_version" {
  description = "Minimum TLS version."
  type        = string
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
