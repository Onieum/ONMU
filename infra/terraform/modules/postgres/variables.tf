variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "server_name" {
  description = "PostgreSQL Flexible Server name."
  type        = string
}

variable "database_name" {
  description = "Application database name."
  type        = string
}

variable "administrator_login" {
  description = "PostgreSQL administrator login name."
  type        = string
}

variable "administrator_password" {
  description = "PostgreSQL administrator password supplied outside git, usually through protected CI variables."
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
}

variable "sku_name" {
  description = "Flexible Server SKU."
  type        = string
}

variable "storage_mb" {
  description = "Storage size in MB."
  type        = number
}

variable "backup_retention_days" {
  description = "Backup retention days."
  type        = number
}

variable "zone" {
  description = "Optional availability zone."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled before private networking is introduced."
  type        = bool
}

variable "enabled_extensions" {
  description = "PostgreSQL extensions to allow at server level. Table/index DDL remains Flyway-owned."
  type        = list(string)
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
