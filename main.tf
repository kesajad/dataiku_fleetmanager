resource "azurerm_user_assigned_identity" "fm_identitiy" {
  location            = var.location
  name                = "uai-${var.env}-fm"
  resource_group_name = local.resource_group
}

resource "azurerm_user_assigned_identity" "instance_identitiy" {
  location            = var.location
  name                = "uai-${var.env}-instance"
  resource_group_name = local.resource_group
}

resource "azurerm_public_ip" "pub_ip" {
  name                = "pip-${var.env}"
  resource_group_name = local.resource_group
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "allow-${var.env}"
  location            = var.location
  resource_group_name = local.resource_group
}

resource "azurerm_network_interface" "pub_nic" {
  name                = "nic-${var.env}-pub"
  location            = var.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip.id
  }
}

resource "azurerm_network_interface" "priv_nic" {
  name                = "nic-${var.env}-priv"
  location            = var.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_rule" "nsr" {
  name                        = "IngressAllowForFM"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "80", "443"]
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = local.resource_group
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "datadisk-${var.env}"
  location             = var.location
  resource_group_name  = local.resource_group
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
}

resource "azurerm_virtual_machine" "fm_vm" {
  name                  = "vm-${var.env}"
  location              = var.location
  resource_group_name   = local.resource_group
  network_interface_ids = [azurerm_network_interface.pub_nic.id]
  vm_size               = "Standard_DS1_v2"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.fm_identitiy.id]
  }
  plan {
    name      = "fm-12"
    publisher = "dataiku"
    product   = "fleet-manager"
  }
  storage_image_reference {
    publisher = "dataiku"
    offer     = "fleet-manager"
    sku       = "fm-12"
    version   = "latest"
  }
  storage_os_disk {
    name          = "osdisk-${var.env}"
    create_option = "FromImage"
  }
  storage_data_disk {
    name            = "datadisk-${var.env}"
    lun             = 3
    create_option   = "Attach"
    managed_disk_id = azurerm_managed_disk.data_disk.id
    disk_size_gb    = 128
  }
  os_profile {
    computer_name  = "FleetManager"
    admin_username = var.ssh_user
    custom_data    = base64encode(local.custom_data)
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = data.azurerm_key_vault_secret.kv_secret_pubkey.value
      path     = format("/home/%s/.ssh/authorized_keys", var.ssh_user)
    }
  }

  depends_on = [azurerm_managed_disk.data_disk]

}
