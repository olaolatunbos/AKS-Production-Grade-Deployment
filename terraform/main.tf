
# Azure Virtual Network
# module "vnet" {
#   source                        = "./modules/virtual_network"
#   virtual_network_name          = var.virtual_network_name
#   subnet_name                   = var.subnet_name
#   resource_location             = var.location
#   resource_group_name           = var.resource_group_name
#   deployment_environment        = var.environment
#   virtual_network_address_space = ["10.224.0.0/12"]
#   subnet_address_prefixes       = ["10.224.0.0/16"]
# }

# DNS Zone
module "dns-zone" {
  source              = "./modules/dns_zone"
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name

}

# Azure Container Registry
module "container-registry" {
  source              = "./modules/container_registry"
  name                = var.container_registry_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "res-0" {
  automatic_upgrade_channel           = "patch"
  azure_policy_enabled                = false
  cost_analysis_enabled               = false
  dns_prefix                          = "cluster-dns"
  http_application_routing_enabled    = false
  image_cleaner_enabled               = true
  image_cleaner_interval_hours        = 168
  kubernetes_version                  = "1.32.5"
  local_account_disabled              = false
  location                            = "uksouth"
  name                                = "cluster"
  node_os_upgrade_channel             = "NodeImage"
  node_resource_group                 = "MC_2048-app-prod-rg_cluster_uksouth"
  oidc_issuer_enabled                 = true
  open_service_mesh_enabled           = false
  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = false
  resource_group_name                 = "2048-app-prod-rg"
  role_based_access_control_enabled   = true
  run_command_enabled                 = true
  sku_tier                            = "Free"
  support_plan                        = "KubernetesOfficial"
  tags = {
    Environment = "Production"
  }
  workload_identity_enabled = true
  default_node_pool {
    auto_scaling_enabled         = true
    fips_enabled                 = false
    host_encryption_enabled      = false
    kubelet_disk_type            = "OS"
    max_count                    = 5
    max_pods                     = 110
    min_count                    = 2
    name                         = "agentpool"
    node_count                   = 2
    node_labels                  = {}
    node_public_ip_enabled       = false
    vnet_subnet_id               = "/subscriptions/001a4eb4-4cb2-47b9-a3bd-de9b5304872c/resourceGroups/2048-app-prod-rg/providers/Microsoft.Network/virtualNetworks/2048-app-prod-rg-vnet/subnets/default"
    only_critical_addons_enabled = false
    orchestrator_version         = "1.32.5"
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    os_sku                       = "Ubuntu"
    scale_down_mode              = "Delete"
    tags = {
      Environment = "Production"
    }
    type              = "VirtualMachineScaleSets"
    ultra_ssd_enabled = false
    vm_size           = "Standard_DS2_v2"
    zones             = []
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
  maintenance_window_auto_upgrade {
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 8
    frequency    = "Weekly"
    interval     = 1
    start_date   = "2025-07-17T00:00:00Z"
    start_time   = "00:00"
    utc_offset   = "+00:00"
  }
  maintenance_window_node_os {
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 8
    frequency    = "Weekly"
    interval     = 1
    start_date   = "2025-07-17T00:00:00Z"
    start_time   = "00:00"
    utc_offset   = "+00:00"
  }
}
