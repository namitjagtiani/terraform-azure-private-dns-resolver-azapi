provider "azurerm" {
  features {}
  client_id       = var.cl_id
  client_secret   = var.cl_sec
  subscription_id = var.sub_id
  tenant_id       = var.ten_id
}

provider "azapi" {
  client_id       = var.cl_id
  client_secret   = var.cl_sec
  subscription_id = var.sub_id
  tenant_id       = var.ten_id
}