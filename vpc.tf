data "aws_vpc" "kubernetes" {
  id = local.create_vpc ? aws_vpc.kubernetes[0].id : var.vpc_id
}

resource "aws_vpc" "kubernetes" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

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

data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.kubernetes.id
  filter {
    name   = "association.main"
    values = [true]
  }
}

resource "aws_route" "internet" {
  count                  = local.create_vpc ? 1 : 0
  route_table_id         = data.aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

resource "aws_subnet" "kubernetes" {
  for_each = {
    for index, subnet in var.public_subnets :
    subnet.cidr_block => subnet # works since cidr blocks need to be unique
  }
  vpc_id                  = data.aws_vpc.kubernetes.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.name} Public ${each.value.az}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

resource "aws_subnet" "kubernetes-private" {
  for_each = {
    for index, subnet in var.private_subnets :
    subnet.cidr_block => subnet # works since cidr blocks need to be unique
  }
  vpc_id                  = data.aws_vpc.kubernetes.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name                                          = "${var.name} Private ${each.value.az}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
