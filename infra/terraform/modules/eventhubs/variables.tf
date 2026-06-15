variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "namespace_name" {
  description = "Event Hubs namespace name."
  type        = string
}

variable "sku" {
  description = "Event Hubs SKU."
  type        = string
}

variable "capacity" {
  description = "Throughput units for Standard SKU."
  type        = number
}

variable "eventhubs" {
  description = "Event hub definitions keyed by event hub name."
  type = map(object({
    partition_count   = number
    message_retention = number
    consumer_groups   = set(string)
  }))
}

variable "tags" {
  description = "Required common tags."
  type        = map(string)
}
