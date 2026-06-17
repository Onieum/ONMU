variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name" {
  description = "Azure Managed Redis name."
  type        = string
}

variable "sku_name" {
  description = "Azure Managed Redis SKU name."
  type        = string
}

variable "public_network_access" {
  description = "Public network access setting."
  type        = string
}

variable "high_availability_enabled" {
  description = "Enable high availability for the Managed Redis instance."
  type        = bool
}

variable "default_database" {
  description = "Default database configuration for Azure Managed Redis."
  type = object({
    access_keys_authentication_enabled = bool
    client_protocol                    = string
    clustering_policy                  = string
    eviction_policy                    = string
  })
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
