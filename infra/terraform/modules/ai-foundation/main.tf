resource "azurerm_machine_learning_workspace" "this" {
  name                          = var.machine_learning_workspace_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  application_insights_id       = var.application_insights_id
  key_vault_id                  = var.key_vault_id
  storage_account_id            = var.storage_account_id
  container_registry_id         = var.container_registry_id
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account" "vision_openai" {
  name                          = var.vision_openai_account_name
  custom_subdomain_name         = var.vision_openai_custom_subdomain_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.vision_openai_sku_name
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "vision" {
  count = var.vision_openai_deployment == null ? 0 : 1

  name                 = var.vision_openai_deployment.name
  cognitive_account_id = azurerm_cognitive_account.vision_openai.id

  model {
    format  = "OpenAI"
    name    = var.vision_openai_deployment.model_name
    version = var.vision_openai_deployment.model_version
  }

  sku {
    name     = var.vision_openai_deployment.sku_name
    capacity = var.vision_openai_deployment.capacity
  }
}

locals {
  runtime_role_assignments = var.create_runtime_role_assignments && var.runtime_principal_id != null ? {
    storage_blob_data_contributor = {
      scope = var.storage_account_id
      role  = "Storage Blob Data Contributor"
    }
    cognitive_services_openai_user = {
      scope = azurerm_cognitive_account.vision_openai.id
      role  = "Cognitive Services OpenAI User"
    }
    azureml_data_scientist = {
      scope = azurerm_machine_learning_workspace.this.id
      role  = "AzureML Data Scientist"
    }
    eventhubs_data_sender = {
      scope = var.eventhubs_namespace_id
      role  = "Azure Event Hubs Data Sender"
    }
    eventhubs_data_receiver = {
      scope = var.eventhubs_namespace_id
      role  = "Azure Event Hubs Data Receiver"
    }
  } : {}

  filtered_runtime_role_assignments = {
    for key, assignment in local.runtime_role_assignments :
    key => assignment
    if assignment.scope != null && assignment.scope != ""
  }
}

resource "azurerm_role_assignment" "runtime" {
  for_each = local.filtered_runtime_role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = var.runtime_principal_id
}
