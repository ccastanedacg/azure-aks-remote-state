resource "azurerm_resource_group" "aks" {
  name     = "rg-${var.cluster_name}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = [var.vnet_cidr]
  tags                = local.common_tags
}

resource "azurerm_subnet" "system" {
  name                 = "snet-aks-system"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.system_subnet_cidr]
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-aks-workloads"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.workload_subnet_cidr]
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "log-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}-cp"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = azurerm_subnet.system.id
    zones                        = ["1", "2", "3"]
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 5
    os_disk_size_gb              = 64
    os_disk_type                 = "Ephemeral"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    ebpf_data_plane     = "cilium"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.aks_network_contributor]
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "workloads"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.workload_node_vm_size
  vnet_subnet_id        = azurerm_subnet.workload.id
  zones                 = ["1", "2", "3"]
  mode                  = "User"
  enable_auto_scaling   = true
  min_count             = var.workload_min_nodes
  max_count             = var.workload_max_nodes
  os_disk_size_gb       = 100
  os_disk_type          = "Ephemeral"

  upgrade_settings {
    max_surge = "33%"
  }

  tags = local.common_tags
}
