output "resource_group_name" {
  value       = azurerm_resource_group.aks.name
  description = "Resource group containing the AKS cluster"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.this.name
  description = "Name of the AKS cluster"
}

output "aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.this.id
  description = "Resource ID of the AKS cluster"
}

output "oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
  description = "OIDC issuer URL used for Azure Workload Identity federation"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  description = "Object ID of the managed kubelet identity (use for ACR pull role assignments)"
}
