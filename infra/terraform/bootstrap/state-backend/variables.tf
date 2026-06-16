variable "subscription_id" {
  description = "Azure subscription id for provider auth when used by CI or local plan."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the tfstate resource group and storage account."
  type        = string
  default     = "koreacentral"
}

variable "resource_group_name" {
  description = "Dedicated resource group name for Terraform state backend resources."
  type        = string
  default     = "rg-onmu-tfstate-krc-001"
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name for Terraform state. Adjust suffix if unavailable."
  type        = string
  default     = "stonmutfstatekrc001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters and numbers."
  }
}

variable "container_name" {
  description = "Private blob container name for Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "replication_type" {
  description = "Storage account replication type for the bootstrap backend."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}

variable "staging_state_key" {
  description = "Terraform state key for staging."
  type        = string
  default     = "onmu/staging/terraform.tfstate"
}

variable "prod_state_key" {
  description = "Terraform state key for production."
  type        = string
  default     = "onmu/prod/terraform.tfstate"
}

variable "operator_principal_object_ids" {
  description = "Operator Microsoft Entra object ids that can read and write Terraform state blobs."
  type        = set(string)
  default     = []
}

variable "github_actions_principal_object_ids" {
  description = "GitHub Actions workload identity principal object ids that can read and write Terraform state blobs."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Common tags for Terraform state backend resources."
  type        = map(string)
  default = {
    app                 = "onmu"
    env                 = "shared"
    owner               = "onmu-team"
    cost_center         = "onmu-infra"
    managed_by          = "terraform-bootstrap"
    data_classification = "internal"
  }
}
