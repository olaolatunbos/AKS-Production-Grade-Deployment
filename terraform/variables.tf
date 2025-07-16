variable "dns_zone_name" {
  type        = string
  description = "Azure DNS Zone name"
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "container_registry_name" {
  type        = string
  description = "Container registry name"
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual Network Name"
}

variable "subnet_name" {
  type        = string
  description = "Subnet Name"
}

variable "environment" {
  type        = string
  description = "Environment"

}
