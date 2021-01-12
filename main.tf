 provider "azurerm" {
     version = "2.42.0"
 features {}
 }

 resource "azurerm_resource_group" "web_server_rg" {
     count = var.Gateways_required
        name        = "${var.web_server_rg}-${count.index}"
    location    = var.web_server_location
 }
  
  resource "azurerm_virtual_network" "web_vnet" {
      count               = var.Gateways_required
    name                ="${var.resource_prefix}-vnet"
    location            = var.web_server_location
    resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
    address_space       = [var.web_server_address_space]
  }

  resource "azurerm_subnet" "web_subnet" {
      count               = var.Gateways_required
      name                  = "${var.resource_prefix}-subnet"
      resource_group_name   = azurerm_resource_group.web_server_rg[count.index].name
      virtual_network_name  = azurerm_virtual_network.web_vnet[count.index].name
      address_prefixes        = [var.web_server_subnet]
  }

  resource "azurerm_network_interface" "web_server_nic" {
      count               = var.Gateways_required
      name                  = "${var.web_server_name}-nic"
      location                = var.web_server_location
       resource_group_name   = azurerm_resource_group.web_server_rg[count.index].name
  
  ip_configuration {
     
            name = "${var.web_server_name}-ip"
            subnet_id = azurerm_subnet.web_subnet[count.index].id
            private_ip_address_allocation = "dynamic" 
            public_ip_address_id = azurerm_public_ip.web_public_ip[count.index].id
  }
  }

  resource"azurerm_public_ip" "web_public_ip" {
      count               = var.Gateways_required
      name                  = "${var.resource_prefix}-public_ip"
      resource_group_name   = azurerm_resource_group.web_server_rg[count.index].name
      location                = var.web_server_location
      allocation_method     = var.environment == "production" ? "Static" : "Dynamic"
  }

resource "azurerm_network_security_group" "web_server_nsg" {
        count               = var.Gateways_required
        name                = "${var.resource_prefix}-nsg"
        location            =   var.web_server_location
        resource_group_name =   azurerm_resource_group.web_server_rg[count.index].name
}

resource "azurerm_network_security_rule" "web_nsg_rule_rdp"{
    count                       = var.Gateways_required
    name                        = "RDP Inbound" 
    priority                    = 105
    direction                   = "inbound" 
    access                      = "Allow" 
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = var.MyCurrentIP
    destination_address_prefix  = "*"
    resource_group_name         = azurerm_resource_group.web_server_rg[count.index].name
    network_security_group_name = azurerm_network_security_group.web_server_nsg[count.index].name
}

resource "azurerm_network_interface_security_group_association" "web_server_association" {
     count                       = var.Gateways_required
     network_security_group_id  = azurerm_network_security_group.web_server_nsg[count.index].id
     network_interface_id       = azurerm_network_interface.web_server_nic[count.index].id
}


resource "azurerm_windows_virtual_machine" "web_server" {
    count                       = var.Gateways_required
    name            = var.web_server_name
    location            =   var.web_server_location
    resource_group_name         = azurerm_resource_group.web_server_rg[count.index].name
    network_interface_ids = [azurerm_network_interface.web_server_nic[count.index].id]
    size = var.desired_server_size
    admin_username = var.Admintobe
    admin_password = var.Magic_Word
    
    os_disk {
     caching = "ReadWrite"
     storage_account_type = "Standard_LRS"

    }

    source_image_reference {
        publisher = var.desired_publisher
        offer = var.desired_offer
        sku = var.desired_sku
        version = var.desired_version
    }
}

 
