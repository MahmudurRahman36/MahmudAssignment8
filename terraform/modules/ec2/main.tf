# ==============================================================================
# Module: EC2
# Generic EC2 instance builder.
# Fetches the latest Ubuntu 22.04 LTS AMI dynamically.
# ==============================================================================

# Fetch latest Ubuntu 22.04 LTS AMI — canonical owner, HVM, SSD
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  # user_data runs once on first boot — optional bootstrap script
  user_data = var.user_data

  # Prevent accidental root volume deletion issues
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.name}-root-vol"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.name
    Role = var.role
  }
}
