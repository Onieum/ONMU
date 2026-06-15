terraform {
  # Backend bootstrap 리소스는 별도 승인 전까지 만들지 않는다.
  # 확정 state key 형식: onmu/prod/terraform.tfstate
  backend "azurerm" {}
}
