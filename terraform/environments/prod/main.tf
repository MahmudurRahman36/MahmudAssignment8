# ==============================================================================
# Environment: prod
# Composition Orchestrator using Modular, Training-Compatible Configurations
# Uses local backend by default for safe local development.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "mahmud"
    }
  }
}

# ==============================================================================
# NETWORKING
# ==============================================================================
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment
}

# ==============================================================================
# SECURITY GROUPS
# ==============================================================================
module "security_groups" {
  source           = "../../modules/security-group"
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# ==============================================================================
# COMPUTE TIER (Monitoring Server)
# ==============================================================================
module "monitoring_server" {
  source             = "../../modules/ec2"
  name               = "${var.project_name}-${var.environment}-server"
  role               = "monitoring"
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security_groups.monitoring_sg_id]
  key_name           = var.key_name
}
