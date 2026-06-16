output "namespace_id" {
  value = azurerm_eventhub_namespace.this.id
}

output "eventhub_names" {
  value = [for eventhub in azurerm_eventhub.this : eventhub.name]
}

output "consumer_group_names" {
  value = [for group in azurerm_eventhub_consumer_group.this : group.name]
}
