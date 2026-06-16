terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  # production도 staging과 같은 원칙을 유지한다.
  # 필요한 Resource Provider는 선등록 상태를 전제로 하고 auto-registration을 끈다.
  resource_provider_registrations = "none"
  features {}
}
