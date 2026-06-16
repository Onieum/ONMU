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
  # GitHub OIDC apply identity는 resource group scope 권한만 갖도록 유지한다.
  # 필요한 Resource Provider는 운영자가 미리 등록한 상태를 전제로 하고,
  # Terraform이 subscription scope에서 auto-registration을 시도하지 않게 막는다.
  resource_provider_registrations = "none"
  features {}
}
