locals {
  bootscript = <<-EOT
    #!/bin/bash
    export FM_CLOUD=AZURE
    subscription_id = ${data.azurerm_client_config.current.subscription_id}
    export FM_SERVER_CIDR="$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/subnet/0/address?api-version=2017-04-02&format=text")/$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/subnet/0/prefix?api-version=2017-04-02&format=text")"
    export FM_SERVER_REGION=${var.location}
    export FM_SERVER_VPCID=${data.azurerm_virtual_network.vnet.id}
    export FM_SERVER_URL=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
    export FM_SERVER_SUBNETID=${data.azurerm_subnet.snet.id}
    export AZURE_MANAGED_IDENTITY_ID=${azurerm_user_assigned_identity.fm_identitiy.id}
    export User=${var.fm_user}
    export PasswordBase64=${base64encode(var.fm_pass)}
    export ADMIN_USER_NAME=${var.ssh_user}
    /opt/dataiku/bin/fm-userdata.sh
  EOT
  custom_data = format(local.bootscript)
  resource_group = data.azurerm_resource_group.rg.name
}
