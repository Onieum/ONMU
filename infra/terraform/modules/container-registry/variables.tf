variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name" {
  description = "Azure Container Registry name."
  type        = string
}

variable "sku" {
  description = "Azure Container Registry SKU."
  type        = string
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
