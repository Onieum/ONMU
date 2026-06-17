variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "account_name" {
  description = "Storage account name."
  type        = string
}

variable "replication_type" {
  description = "Storage replication type."
  type        = string
}

variable "media_container_name" {
  description = "Media blob container name."
  type        = string
}

variable "tile_container_name" {
  description = "Tile blob container name."
  type        = string
}

variable "tile_cors_allowed_origins" {
  description = "Allowed origins for public tile/static blob reads."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
