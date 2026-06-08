output "monitoring_sg_id" {
  description = "Security Group ID for the Monitoring EC2 server"
  value       = aws_security_group.monitoring.id
}
