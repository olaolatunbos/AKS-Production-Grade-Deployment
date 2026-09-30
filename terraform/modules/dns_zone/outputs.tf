output "dns_zone_name" {
  description = "The name of the DNS Zone."
  value       = azurerm_dns_zone.this.name
}

output "dns_zone_id" {
  description = "The ID of the DNS Zone."
  value       = azurerm_dns_zone.this.id
}

output "dns_zone_name_servers" {
  description = "The name servers of the DNS Zone."
  value       = azurerm_dns_zone.this.name_servers
}
