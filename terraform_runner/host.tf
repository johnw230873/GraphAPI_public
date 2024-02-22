resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = "${var.prefix}-${var.vm_name}"
  resource_group_name             = azurerm_resource_group.rgp1.name
  location                        = azurerm_resource_group.rgp1.location
  size                            = var.vm_size
  network_interface_ids           = [azurerm_network_interface.ni1.id]
  admin_username                  = var.username
  admin_password                  = var.userpassword
  disable_password_authentication = false

  boot_diagnostics {
    storage_account_uri = ""
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }


}



resource "null_resource" "example" {
  depends_on = [azurerm_linux_virtual_machine.vm1]
  triggers = {
    instance_id = azurerm_linux_virtual_machine.vm1.id
  }
  connection {
    type     = "ssh"
    user     = var.username
    password = var.userpassword
    host     = azurerm_linux_virtual_machine.vm1.public_ip_address
  }


  #copy file from Agent to local computer under /tmp directory
  provisioner "file" {
    source      = "${path.module}/scripts/deploy-terraform-agents-vm1.sh"
    destination = "/tmp/deploy-terraform-agents-vm1.sh"
  }

  #Run the file on th elocal computer as this user.
  #As we are running the command as Sudo we need to pass the enviroment variables during the calling of the file (new session)
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy-terraform-agents-vm1.sh",
      "sudo TFC_AGENT_VERSION=${var.tfc_agent_version_vm1} TFC_AGENT_1_NAME=${var.prefix}-${var.vm_name}_TFC_Agent_1 TFC_AGENT_1_TOKEN=${var.tfc_agent_token_vm_1_agent_1} /tmp/deploy-terraform-agents-vm1.sh"
    ]
  }
}
