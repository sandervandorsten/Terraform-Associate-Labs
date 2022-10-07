terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }
  cloud {
    organization = "digital-power"
    workspaces {
      name = "provisioners"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  id = "vpc-010f2032de5271596"
}

data "template_file" "cloud-init" {
  template = file("./cloud-init.yaml")
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLor3mfiR1umgt4mxwXhUwEmTt61Plb8Z6naElDSAOto0ehp5SJFPNVa0cXdDjZeN3JN1ilnyt55u/C0ZQ2J83nHOVtnpDoBSSgTZfKZVrmHhrx2+N4o4rUTwIUs0PRO6N/vZNnihm8nnmLRM754RnvPPxlAi3/YXagJhrCR0t9GL8WolK7A1vkAr/B09BAjgR2s/DNLv2pkKpeP2NwK9jgheCHaBypyD3FKyI4i8/5kwm5A5jc4HUIzDXx6ZhoKX5CT+VI2G17AzlFlrVu9ImWSFg899cBdOuQUXV55crL/ZXHXj5Mwj4D1I4GKl+OughfEJ5k0gO5T4gXlvQUTMBC9iBKbVo+3X29rmiYPpLC/1HJWx54+OP/xArr7b+1grIQ9LzyO2oQXz6mYShL0SeM+0I2Rq9CQ7h9Jzf+9ow5oL+NWZpCK+/xI63WfB2rtH1Ei4mbOacW+FjTjnwW/BB7+gypw0Y6DC84aBh1iVoWrR6eClxLelvSG3sgdLcGv0hYOIKlLnADny9Ks2+vLnid6qROE8R7vqpaX2Q2zQFlAXcKj4W/kRosXHULJrgztrQO5HdzAdCzf/G45JRXq0nA/QOPg/zJSmdhqBxMZtIpsXJcaMa8yXuCY7ald1Dk3VMX1r0wzGcxMLk1KcqMn5ak4w5XES1ysDTRu6zTWbLeQ== sander@Sanders-MacBook-Pro"
}


resource "aws_security_group" "TerraformDemoSG1" {
  name        = "TerraformDemoSG1"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress = [
    {
      description      = "Allow incoming traffic over HTTP"
      from_port        = 80
      protocol         = "TCP"
      to_port          = 80
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow incoming traffic over SSH"
      from_port        = 22
      protocol         = "TCP"
      to_port          = 22
      cidr_blocks      = ["83.85.147.230/32"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  tags = {
    Maintainer  = local.maintainer
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_instance" "myserver" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.TerraformDemoSG1.id]
  user_data              = data.template_file.cloud-init.rendered

  tags = {
    Name        = "Server1"
    Maintainer  = local.maintainer
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "null_resource" "status" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids=${aws_instance.myserver.id}"
  }
}