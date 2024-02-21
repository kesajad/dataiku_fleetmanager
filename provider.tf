provider "azurerm" {
  subscription_id = data.azurerm_client_config.current.subscription_id
  features {

  }
}
