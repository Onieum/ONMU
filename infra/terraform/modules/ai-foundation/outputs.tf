output "machine_learning_workspace_id" {
  value = azurerm_machine_learning_workspace.this.id
}

output "machine_learning_workspace_name" {
  value = azurerm_machine_learning_workspace.this.name
}

output "vision_openai_account_id" {
  value = azurerm_cognitive_account.vision_openai.id
}

output "vision_openai_account_name" {
  value = azurerm_cognitive_account.vision_openai.name
}

output "vision_openai_endpoint" {
  value = azurerm_cognitive_account.vision_openai.endpoint
}

output "vision_openai_deployment_name" {
  value = try(azurerm_cognitive_deployment.vision[0].name, null)
}
