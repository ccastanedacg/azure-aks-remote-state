variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for the state storage account"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-tfstate-mgmt-eastus2"
  description = "Resource group hosting the remote state storage account"
}

variable "container_name" {
  type        = string
  default     = "tfstate"
  description = "Blob container name where .tfstate files and lease locks are stored"
}
