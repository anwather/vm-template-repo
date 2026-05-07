# vm-template-repo

Terraform templates consumed by the **Task Orchestrator** hosted agents (one
agent per OS family). Each subfolder is a self-contained Terraform module
with the same variable contract; the agent selects which subfolder to run
inside via the `TEMPLATE_SUBFOLDER` environment variable.

## Layout

| Path        | Used by                              | OS family         |
|-------------|--------------------------------------|-------------------|
| `windows/`  | `vmagent-agent` hosted agent         | Windows Server    |
| `linux/`    | `vmagent-agent-linux` hosted agent   | Ubuntu / RHEL     |

Both modules share the same seven-variable contract and emit the same output
shape so the agent's tool layer is OS-agnostic. The only differences are:

- Allowed `os_image` enum (set per agent via `ALLOWED_OS_IMAGES_JSON`).
- Resource type (`azurerm_windows_virtual_machine` vs
  `azurerm_linux_virtual_machine`).
- The Linux module sets `disable_password_authentication = false` so the
  generated random password works for SSH.

## Contract (both modules)

| Variable          | Source                                                      |
|-------------------|-------------------------------------------------------------|
| `vm_name`         | User input. Windows: 2-15 chars. Linux: 1-64, lowercase.    |
| `resource_group`  | User input. Created by template if it doesn't exist.        |
| `location`        | Azure region short name.                                    |
| `vm_size`         | Azure VM SKU.                                               |
| `os_image`        | One of the keys in `local.image_map`.                       |
| `admin_username`  | Local admin username.                                       |
| `subnet_id`       | Full ARM ID of a pre-existing subnet.                       |

## Supported `os_image` values

### Windows (`windows/locals.tf`)

| `os_image`                       | Marketplace SKU                |
|----------------------------------|--------------------------------|
| `WindowsServer2022-smalldisk`    | `2022-datacenter-smalldisk`    |
| `WindowsServer2025-smalldisk`    | `2025-datacenter-smalldisk`    |

### Linux (`linux/locals.tf`)

| `os_image`    | Publisher / Offer / SKU                                            |
|---------------|--------------------------------------------------------------------|
| `Ubuntu2204`  | `Canonical` / `0001-com-ubuntu-server-jammy` / `22_04-lts-gen2`    |
| `Ubuntu2404`  | `Canonical` / `ubuntu-24_04-lts` / `server`                        |
| `RHEL9`       | `RedHat` / `RHEL` / `9-lvm-gen2`                                   |

To add a new option:

1. Add a row to `local.image_map` in the relevant subfolder's `locals.tf`.
2. Add the same string to the `os_image` validation list in `variables.tf`.
3. Update the agent's `ALLOWED_OS_IMAGES_JSON` env var in
   `deploy/deploy_agent.py` (`AGENT_PROFILES`).

## Outputs (both modules)

`vm_id`, `vm_name`, `resource_group`, `location`, `os_image`, `image_sku`,
`private_ip_address`, `admin_username`.

The admin password is intentionally NOT emitted as a Terraform output. The
runner stores it (or a secret URI) in Key Vault separately.

## Local testing

```bash
cd windows   # or: cd linux
cp terraform.tfvars.example terraform.tfvars.json
# edit values
terraform init -backend=false
terraform validate
```
