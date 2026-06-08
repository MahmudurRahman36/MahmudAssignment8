# ==============================================================================
# Module: Security Groups
# Creates a security group for the monitoring server with least-privilege rules.
# Allows ports:
#   - 22 (SSH) from allowed_ssh_cidr
#   - 3001 (Grafana dashboard) from anywhere (0.0.0.0/0)
#   - 9090 (Prometheus UI) from anywhere (0.0.0.0/0)
#   - 3100 (Loki API) from anywhere (0.0.0.0/0)
# ==============================================================================

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-${var.environment}-monitoring-sg"
  description = "Security group for DevOps monitoring server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Grafana UI Ingress"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus UI Ingress"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Loki API Ingress"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-monitoring-sg"
  }
}
