terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg-unyleya1" {
  name     = "unyleya-devops"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr1" {
  name                = "acrUnyleya"
  resource_group_name = azurerm_resource_group.rg-unyleya1.name
  location            = azurerm_resource_group.rg-unyleya1.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks1" {
  name                = "aksUnyleya"
  location            = azurerm_resource_group.rg-unyleya1.location
  resource_group_name = azurerm_resource_group.rg-unyleya1.name
  dns_prefix          = "aks1-dns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin = "kubenet"
  }

  # service_principal {
  #   client_id = var.client_id
  #   client_secret = var.client_secret
  # }

  role_based_access_control {
    enabled = true
  }

}

resource "azurerm_role_assignment" "aks1_to_acr1" {
  scope                = azurerm_container_registry.acr1.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks1.kubelet_identity.0.object_id
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.aks1.id
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks1.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks1.kube_config_raw

  sensitive = true
}

output "acr_id" {
  value = azurerm_container_registry.acr1.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr1.login_server
}