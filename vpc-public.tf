
# ==================
# Items to create when using public node groups
# ==================

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
