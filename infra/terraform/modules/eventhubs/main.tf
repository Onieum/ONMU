locals {
  consumer_groups = flatten([
    for eventhub_name, eventhub in var.eventhubs : [
      for group_name in eventhub.consumer_groups : {
        key           = "${eventhub_name}:${group_name}"
        eventhub_name = eventhub_name
        group_name    = group_name
      }
    ]
  ])
}

resource "azurerm_eventhub_namespace" "this" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity
  tags                = var.tags
}

resource "azurerm_eventhub" "this" {
  for_each            = var.eventhubs
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention
}

resource "azurerm_eventhub_consumer_group" "this" {
  for_each            = { for group in local.consumer_groups : group.key => group }
  name                = each.value.group_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[each.value.eventhub_name].name
  resource_group_name = var.resource_group_name
}
