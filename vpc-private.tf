
# ==================
# Items to create when using private node groups
# ==================

# Internet gateway and routing for nat subnet
resource "aws_internet_gateway" "nat_gw" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id

  tags = {
    Name = "${local.friendly_name} Internet Gateway for NAT"
  }
}

# create a public subnet for the nat gateway if one is not provided
resource "aws_subnet" "nat_gateway_public" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id

  cidr_block              = var.private_subnets.nat_gateway.cidr_block
  availability_zone       = var.private_subnets.nat_gateway.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prog_name}-kubernetes-nat-gateway-public"
  }
}

# add a routing table for the public subnet
resource "aws_route_table" "nat_gateway_public" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nat_gw[0].id
  }

  tags = {
    Name = "${var.prog_name}-kubernetes-private-nat-gateway-to-public"
  }
}

resource "aws_route_table_association" "nat_gateway_public" {
  count          = local.create_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.nat_gateway_public[0].id
  route_table_id = aws_route_table.nat_gateway_public[0].id
}

#provision a NAT gateway and IP address for nonpublic instances to use to access the internet
resource "aws_eip" "nat-gateway" {
  count = local.create_nat_gateway ? 1 : 0
}

resource "aws_nat_gateway" "gw" {
  count         = local.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat-gateway[0].id
  subnet_id     = aws_subnet.nat_gateway_public[0].id

  tags = {
    Name = "NAT Gateway for private instances"
  }
}

data "aws_nat_gateway" "gw" {
  id    = local.create_nat_gateway ? aws_nat_gateway.gw[0].id : var.private_subnets.nat_gateway.gateway_id
}

# add a routing table for pods and hosts on our private subnets
resource "aws_route_table" "workload_private" {
  count  = length(var.private_subnets.networks) > 0 ? 1 : 0
  vpc_id = data.aws_vpc.kubernetes.id

  tags = {
    Name = "${var.prog_name}-kubernetes-workload-private-subnet-routes"
  }
}

# use the gateway to get to the internet
resource "aws_route" "workload_private_to_nat" {
  depends_on = [ aws_nat_gateway.gw ]
  count                  = length(var.private_subnets.networks) > 0 ? 1 : 0
  route_table_id         = aws_route_table.workload_private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = data.aws_nat_gateway.gw.id
}

# at last, create the subnets
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
