output "diagnostic_setting_ids" {
  value = {
    for name, setting in azurerm_monitor_diagnostic_setting.this :
    name => setting.id
  }
}
