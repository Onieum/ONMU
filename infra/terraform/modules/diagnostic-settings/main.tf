data "azurerm_monitor_diagnostic_categories" "target" {
  for_each    = var.targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = var.targets
  name                       = "${var.name_prefix}-${each.key}-law"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.target[each.key].log_category_types)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.target[each.key].metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [
      enabled_log
    ]
  }
}
