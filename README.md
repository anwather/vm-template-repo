# Windows VM Terraform Template (Agent-Driven)

A reusable, single-root Terraform template that deploys **one Windows virtual machine** into existing Azure networking. It is intended to be consumed by an external automation agent: the agent supplies variable values, runs `terraform init / plan / apply`, and reads outputs (including the Key Vault secret holding the generated admin password).

The template makes no assumptions about *how* it is invoked — only that the agent can:

1. Authenticate to Azure (Azure CLI login, managed identity, service principal env vars, etc.).
2. Supply backend configuration at `terraform init` time.
3. Supply variable values via `terraform.tfvars`, a `*.auto.tfvars`/`.tfvars.json` file, or `TF_VAR_*` environment variables.

---

## What gets deployed

| Resource | Created | Notes |
|---|---|---|
| Resource group | optional (`create_resource_group`) | Otherwise looked up via `data` source |
| Virtual network | **no** | Must already exist; agent provides RG + name |
| Subnet | **no** | Must already exist; agent provides name |
| Key Vault | **no** | Must already exist; agent provides RG + name |
| Public IP | optional (`create_public_ip`) | Standard / Static by default |
| Network interface | yes | Single ipconfig, optional public IP attachment |
| Random admin password | yes | 24 chars, complexity enforced |
| Key Vault secret | yes | Holds the generated admin password |
| Windows VM | yes | Marketplace image, optional SystemAssigned identity, optional boot diagnostics (managed) |
| Managed data disks | optional | List of objects, attached to the VM |

---

## Prerequisites

The principal running Terraform needs at minimum:

- **Target RG (or subscription if creating it)** — `Contributor` (or equivalent custom role with VM/NIC/PIP/disk permissions).
- **Existing virtual network RG** — `Reader` plus `Microsoft.Network/virtualNetworks/subnets/join/action` on the subnet (commonly via `Network Contributor` scoped to the vnet/subnet).
- **Existing Key Vault** — for RBAC-mode vaults: `Key Vault Secrets Officer`. For access-policy vaults: secret `Set/Get/List` permissions.
- An **Azure Storage account + container** for remote Terraform state.

---

## Repository layout

```
.
├── README.md
├── versions.tf               # required_providers, partial backend "azurerm" {}
├── providers.tf              # azurerm provider configuration
├── variables.tf              # all input variables
├── locals.tf                 # naming + tag merging
├── main.tf                   # data lookups, NIC, VM, optional resources
├── outputs.tf                # IDs, IPs, KV secret reference
├── terraform.tfvars.example  # documented example values
└── .gitignore
```

---

## Inputs

See [`variables.tf`](./variables.tf) for the canonical list, types, defaults, and validation. Required (no default) inputs:

- `name`, `location`, `resource_group_name`
- `vnet_resource_group_name`, `vnet_name`, `subnet_name`
- `key_vault_name`, `key_vault_resource_group_name`

The image defaults to **Windows Server 2025 Datacenter Azure Edition (smalldisk)**:

```
publisher = "MicrosoftWindowsServer"
offer     = "WindowsServer"
sku       = "2025-datacenter-azure-edition-smalldisk"
version   = "latest"
```

All four image fields are overridable.

---

## Usage

### 1. Initialise with a remote backend

The template declares an **empty** `backend "azurerm" {}` block so the agent supplies the values:

```bash
terraform init \
  -backend-config="resource_group_name=<state-rg>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=<state-container>" \
  -backend-config="key=<vm-name>.tfstate"
```

(Authentication to the state storage account follows the standard `azurerm` backend rules — see the Terraform docs.)

### 2. Supply variable values

**Option A — `terraform.tfvars` file** (copy from the example):

```bash
cp terraform.tfvars.example terraform.tfvars
# edit values
terraform plan -out tfplan
terraform apply tfplan
```

**Option B — environment variables** (good for agents that prefer not to write files):

```bash
export TF_VAR_name="win-app-01"
export TF_VAR_location="australiaeast"
export TF_VAR_resource_group_name="rg-app-prod"
export TF_VAR_vnet_resource_group_name="rg-network-prod"
export TF_VAR_vnet_name="vnet-prod-ae"
export TF_VAR_subnet_name="snet-app"
export TF_VAR_key_vault_name="kv-secrets-prod"
export TF_VAR_key_vault_resource_group_name="rg-secrets-prod"

# Complex types (objects/lists) are passed as JSON:
export TF_VAR_tags='{"environment":"prod","owner":"platform"}'
export TF_VAR_data_disks='[{"name_suffix":"data01","disk_size_gb":128,"lun":0,"storage_account_type":"Premium_LRS","caching":"ReadWrite"}]'

terraform plan -out tfplan
terraform apply tfplan
```

The two styles can be mixed; `TF_VAR_*` overrides values defined in `*.tfvars` files.

### 3. Retrieve the admin password

The generated password is written to the agent-supplied Key Vault. The secret name (and id) are surfaced as outputs:

```bash
SECRET_NAME=$(terraform output -raw admin_password_secret_name)
KV_NAME=$(terraform output -raw key_vault_id | awk -F/ '{print $NF}')

az keyvault secret show \
  --vault-name "$KV_NAME" \
  --name "$SECRET_NAME" \
  --query value -o tsv
```

The password is **never** placed in Terraform outputs. It only exists in:

- Terraform state (so the state backend must be treated as sensitive).
- The Key Vault secret.

---

## Outputs

| Output | Description |
|---|---|
| `vm_id`, `vm_name`, `resource_group_name` | Identity of the deployed VM |
| `private_ip_address` | NIC private IP |
| `public_ip_address` | Null if `create_public_ip = false` |
| `principal_id` | Null if `enable_system_assigned_identity = false` |
| `admin_username` | Local admin username configured on the VM |
| `admin_password_secret_id` / `admin_password_secret_name` | KV secret holding the password |
| `key_vault_id` | Existing Key Vault used for the secret |
| `data_disk_ids` | Map of `name_suffix` → managed disk ID |

---

## Notes for agents

- The template is intentionally a single root module — set variables, run, done. No module wrapping required.
- `name` must be **1–15 characters** (Windows computer name limit) — validated.
- `private_ip_address` is only honoured when `private_ip_allocation = "Static"`.
- Re-running `apply` with a different `name` produces a fresh VM (resource is keyed on name); changing the existing `name` triggers replacement.
- Adding/removing entries in `data_disks` adds or removes (and detaches) disks; changing `lun` or `disk_size_gb` of an existing entry may force replacement of the disk — review the plan.
- The `random_password` resource will not regenerate on subsequent applies; to rotate, taint it: `terraform taint random_password.admin && terraform apply`.

---

## Validation

Before handing the template to an agent for a real apply, you can sanity-check it with no Azure access:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```
