data "aws_vpc" "kubernetes" {
  id = local.create_vpc ? aws_vpc.kubernetes[0].id : var.vpc_id
}

resource "aws_vpc" "kubernetes" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name       = "${local.friendly_name} VPC"
    CostCenter = var.cost_center
  }
}

#default sg
resource "aws_default_security_group" "kubernetes" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.kubernetes[0].id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

