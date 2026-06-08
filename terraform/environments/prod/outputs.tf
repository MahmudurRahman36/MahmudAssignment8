output "monitoring_server_public_ip" {
  description = "Public IP address of the monitoring server"
  value       = module.monitoring_server.public_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP address of the monitoring server"
  value       = module.monitoring_server.private_ip
}

output "grafana_url" {
  description = "URL to access the Grafana UI"
  value       = "http://${module.monitoring_server.public_ip}:3001"
}

output "prometheus_url" {
  description = "URL to access the Prometheus UI"
  value       = "http://${module.monitoring_server.public_ip}:9090"
}

output "ssh_command" {
  description = "SSH command to connect to the monitoring server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${module.monitoring_server.public_ip}"
}
