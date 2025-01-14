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

# Internet gateway and routing for public items
resource "aws_internet_gateway" "gw" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.kubernetes[0].id

  tags = {
    Name = "${local.friendly_name} Internet Gateway"
  }
}

# find out what the gateway is if we didn't create it
data "aws_internet_gateway" "default_gateway" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.kubernetes.id]
  }
}

# reference to the default routing table
data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.kubernetes.id
  filter {
    name   = "association.main"
    values = [true]
  }
}

# use the gateway to get to the internet
resource "aws_route" "internet" {
  count                  = local.create_vpc ? 1 : 0
  route_table_id         = data.aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}
