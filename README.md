# azure-aks-remote-state

Production-ready Azure Kubernetes Service (AKS) Terraform stack backed by Azure Blob Storage remote state with native blob lease locking and Entra ID (Azure AD) authentication.

## Architecture

```text
+----------------------------------------------------------------------+
| Management RG (rg-tfstate-mgmt-eastus2)                              |
|  └── Storage Account (ZRS, OAuth-only, Versioning, Blob Lease Lock)  |
+----------------------------------------------------------------------+
                                   ^
                                   | (azurerm backend state & lease)
+----------------------------------|-----------------------------------+
| Cluster RG (rg-platform-prod)    |                                   |
|                                                                      |
|  VNet (10.40.0.0/16) — Azure CNI Overlay + Cilium eBPF Data Plane    |
|  ├── snet-aks-system (10.40.1.0/24)                                  |
|  │    └── System Node Pool (Zones 1-3, Standard_D4ds_v5, Ephemeral)  |
|  └── snet-aks-workloads (10.40.16.0/20)                              |
|       └── User Node Pool (Zones 1-3, Autoscaled 2-10, Ephemeral)     |
|                                                                      |
|  Integrations: OIDC Workload Identity | Key Vault CSI | Log Analytics|
+----------------------------------------------------------------------+
```

### Key Capabilities
- **Keyless Remote State Locking**: `bootstrap-state/` provisions a Zone-Redundant Storage (ZRS) account with shared access keys disabled (`shared_access_key_enabled = false`) and blob versioning enabled. Terraform acquires a native Azure Blob Lease during `plan`/`apply` using `use_azuread_auth = true`.
- **Azure CNI Overlay + Cilium**: Avoids VNet IP exhaustion by allocating pod IPs from an overlay CIDR (`192.168.0.0/16`) while enforcing network policies via Cilium eBPF.
- **System / Workload Pool Isolation**: System add-ons run on a dedicated node pool (`only_critical_addons_enabled = true`) across 3 availability zones so application spikes cannot evict CoreDNS or kube-proxy.

## Repository Layout

```text
├── bootstrap-state/          # One-time setup for the remote state Storage Account
└── cluster/                  # VNet, Managed Identity, Log Analytics, and AKS cluster
```

## Deployment

### 1. Bootstrap Remote State Storage

Make sure your user or service principal has `Storage Blob Data Owner` on the subscription or state resource group so it can acquire blob leases via Entra ID.

```bash
az login
cd bootstrap-state

terraform init
terraform apply
```

### 2. Configure Backend & Deploy AKS

Copy the output values from step 1 into `cluster/backend.hcl`:

```bash
cd ../cluster
cp backend.hcl.example backend.hcl
# Update storage_account_name in backend.hcl with the output from bootstrap-state

cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Fetch Cluster Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)
```

## Requirements

- Terraform `>= 1.6.0`
- AzureRM Provider `~> 3.100`
- Azure CLI (`az`) authenticated with permissions to manage RBAC role assignments and storage blob leases
