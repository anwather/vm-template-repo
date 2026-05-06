# vm-template-repo

Terraform template consumed by the [vm-build-agent](https://github.com/anwather/vm-build-agent)
runner Container App Job. The agent's bridge function writes a
`terraform.tfvars.json` with exactly the variables declared in `variables.tf`,
then runs `terraform init` (azurerm backend) and `terraform apply`.

## Contract

The runner emits these seven variables — they MUST stay in sync with
`agent/tools/openapi.json` and `function_app/function_app.py` in the
vm-build-agent repo:

| Variable          | Source                                                      |
|-------------------|-------------------------------------------------------------|
| `vm_name`         | User input. 2–15 chars (Windows NetBIOS).                   |
| `resource_group`  | User input. Created by this template if it doesn't exist.   |
| `location`        | Azure region short name.                                    |
| `vm_size`         | Azure VM SKU.                                               |
| `os_image`        | One of the keys in `local.image_map` (see `locals.tf`).     |
| `admin_username`  | Local admin username.                                       |
| `subnet_id`       | Full ARM ID of a pre-existing subnet.                       |

## Supported `os_image` values

Defined in `locals.tf` as `local.image_map`. To add a new option:

1. Add a row to `local.image_map` with publisher/offer/sku/version.
2. Add the same string to the `os_image` validation list in `variables.tf`.
3. Update `agent/tools/openapi.json` and `agent/instructions.md` in the
   vm-build-agent repo.

Currently supported:

| `os_image`                       | Marketplace SKU                       |
|----------------------------------|---------------------------------------|
| `WindowsServer2022-smalldisk`    | `2022-datacenter-smalldisk`           |
| `WindowsServer2025-smalldisk`    | `2025-datacenter-smalldisk`           |

## Outputs

The runner uploads `terraform output -json` to the outputs blob — the agent
fetches it via `get_deployment_output`. Notable outputs:

- `private_ip_address`
- `admin_username`
- `admin_password` (sensitive)
- `vm_id`, `resource_group`, `location`, `image_sku`

## Local testing

```bash
cp terraform.tfvars.example terraform.tfvars.json
# edit values
terraform init -backend=false
terraform validate
```
