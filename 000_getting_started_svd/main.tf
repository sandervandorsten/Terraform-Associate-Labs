terraform {
  cloud {
    organization = "digital-power"
    workspaces {
      name = "getting-started"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }
}

resource "aws_instance" "server1" {
  ami           = local.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "Server1"
    Maintainer  = local.maintainer
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_instance" "server2" {
  ami           = local.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "Server2"
    Maintainer  = local.maintainer
    Environment = var.environment
    Terraform   = "true"
  }
}
