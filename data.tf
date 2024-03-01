data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = "rg-${var.env}-stag"
}
data "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}-stag"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet" {
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault" "kv" {
  name                = "kv-dataiku-fm-live-stag1"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "kv_secret_pubkey" {
  name         = "sajad-ssh"
  key_vault_id = data.azurerm_key_vault.kv.id
}


# output "vault_uri" {
#   value = data.azurerm_key_vault.kv.vault_uri
# }

# output "virtual_network_id" {
#   value = data.azurerm_virtual_network.vnet.id
# }

# output "subnet_id" {

#   value = data.azurerm_subnet.snet.id
# }

# output "secret_value" {
#   value     = data.azurerm_key_vault_secret.kv_secret_pubkey.value
#   sensitive = true
# }
