
#####
# Managed Kubernetes cluster config
# see https://github.com/terraform-aws-modules/terraform-aws-eks
# and https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
#####

resource "aws_security_group" "kubernetes" {
  name        = local.cluster_name
  description = "Hosts running pods in the ${local.cluster_name} cluster"
  vpc_id      = data.aws_vpc.kubernetes.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [
      module.kubernetes.cluster_primary_security_group_id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.friendly_name} Kubernetes"
  }
}
