variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant id."
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name."
  type        = string
}

variable "user_assigned_identity_name" {
  description = "Managed identity used by runtime to read Key Vault references."
  type        = string
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
