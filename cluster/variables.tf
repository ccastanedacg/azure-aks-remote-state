variable "location" {
  type        = string
  default     = "eastus2"
  description = "Azure region for the cluster and networking"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment"
}

variable "cluster_name" {
  type        = string
  default     = "platform"
  description = "Short identifier for the AKS cluster"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "Kubernetes minor version"
}

variable "vnet_cidr" {
  type        = string
  default     = "10.40.0.0/16"
  description = "Address space for the cluster Virtual Network"
}

variable "system_subnet_cidr" {
  type        = string
  default     = "10.40.1.0/24"
  description = "Subnet CIDR for the system node pool"
}

variable "workload_subnet_cidr" {
  type        = string
  default     = "10.40.16.0/20"
  description = "Subnet CIDR for user workload node pools"
}

variable "system_node_vm_size" {
  type        = string
  default     = "Standard_D4ds_v5"
  description = "VM SKU for system nodes (requires local temp storage for Ephemeral OS disk)"
}

variable "workload_node_vm_size" {
  type        = string
  default     = "Standard_D8ds_v5"
  description = "VM SKU for application workload nodes"
}

variable "workload_min_nodes" {
  type        = number
  default     = 2
  description = "Minimum node count in the user workload pool"
}

variable "workload_max_nodes" {
  type        = number
  default     = 10
  description = "Maximum node count in the user workload pool"
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "Retention period in days for Container Insights logs"
}
