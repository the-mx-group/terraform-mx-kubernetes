
# ==================
# Items to create when using private node groups
# ==================

#also provision a NAT gateway and IP address for nonpublic instances
resource "aws_eip" "nat-gateway" {
  count = local.create_nat_gateway ? 1 : 0
  domain = "vpc"
}

# create a public subnet for the nat gateway if one is not provided
resource "aws_subnet" "public-nat-gateway" {
  count = local.create_nat_gateway && var.private_subnets.nat_gateway.id == "" ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id

  cidr_block              = var.private_subnets.nat_gateway.cidr_block
  availability_zone       = var.private_subnets.nat_gateway.az
  map_public_ip_on_launch = true
}

data "aws_subnet" "public-nat-gateway" {
  count = local.create_nat_gateway ? 1 : 0
  id = var.private_subnets.nat_gateway.id != "" ? var.private_subnets.nat_gateway.id : aws_subnet.public-nat-gateway[0].id
}

resource "aws_nat_gateway" "gw" {
  count = local.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat-gateway[0].id
  subnet_id     = data.aws_subnet.public-nat-gateway[0].id

  tags = {
    Name = "NAT Gateway for private instances"
  }
}

data "aws_nat_gateway" "gw" {
  count = length(var.private_subnets.networks) > 0 ? 1 : 0
  id = local.create_nat_gateway ? aws_nat_gateway.gw[0].id : var.private_subnets.nat_gateway.id
}

# add a routing table for our private subnets
resource "aws_route_table" "default-private" {
  count  = length(var.private_subnets.networks) > 0 ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.gw[0].id
  }

  tags = {
    Name = "${var.prog_name}-kubernetes-private-subnet-routes"
  }
}

# use the gateway to get to the internet
resource "aws_route" "nat-internet" {
  count                  = length(var.private_subnets.networks) > 0 ? 1 : 0
  route_table_id         = aws_route_table.default-private[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_nat_gateway.gw[0].id
}

resource "aws_subnet" "kubernetes-private" {
  for_each = {
    for index, subnet in var.private_subnets.networks :
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
