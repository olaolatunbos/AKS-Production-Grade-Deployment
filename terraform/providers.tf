terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorageacct12"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "4.24.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
  subscription_id = "001a4eb4-4cb2-47b9-a3bd-de9b5304872c"
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.res-0.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.res-0.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.res-0.kube_config[0].cluster_ca_certificate)
  }
}
