terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state is configured by the calling agent at `terraform init` time
  # via `-backend-config="..."` arguments. Example:
  #
  #   terraform init \
  #     -backend-config="resource_group_name=tfstate-rg" \
  #     -backend-config="storage_account_name=tfstateacct" \
  #     -backend-config="container_name=tfstate" \
  #     -backend-config="key=my-vm.tfstate"
  backend "azurerm" {}
}
