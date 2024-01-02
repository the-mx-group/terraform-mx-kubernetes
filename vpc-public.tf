
# ==================
# Items to create when using public node groups
# ==================

# Internet gateway and routing for public items
resource "aws_internet_gateway" "gw" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.kubernetes[0].id

  tags = {
    Name = "${local.friendly_name} Internet Gateway"
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
  count                  = local.create_vpc && length(var.public_subnets) > 0 ? 1 : 0
  route_table_id         = data.aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

# create each subnet for the cluster
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
