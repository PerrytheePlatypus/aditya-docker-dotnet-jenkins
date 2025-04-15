terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  required_version = ">=1.0.0"
}

provider "azurerm" {
  features {}
  subscription_id = "0f9d69f5-ad20-4bba-b635-f1f6dc2c1744" # Your subscription ID
  tenant_id       = "b0b76d6e-14b7-4c08-8657-a19ef23b3b0b" # Your tenant ID
}

# Variables
variable "location" {
  default = "East US 2" # Your location
}

variable "resource_group_name" {
  default = "rg-aks-acr" # Your resource group name
}

variable "acr_name" {
  default = "kubernetesacr04082003" # Your ACR name
}

variable "aks_cluster_name" {
  default = "mycluster040820035" # Your AKS cluster name
}

variable "dns_prefix" {
  default = "myaksdns" # Your DNS prefix
}

variable "node_count" {
  default = 2 # Your node count
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # Set to false as per your original configuration
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "Development"
  }
}

# Role assignment to allow AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
