terraform{
    backend "azurerm" {
        resource_group_name  = "remote-state-PCS"
        storage_account_name = "alvinpcsstorage"
        container_name       = "pcstore"
        key                  = "pcs.tfstate"
    }
}