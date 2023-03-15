#actually provision the kubernetes cluster
module "kubernetes" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.31.2"
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  cluster_addons = merge(
    {
      "vpc-cni" : {
        "addon_version" : "v1.12.5-eksbuild.2",
        "resolve_conflicts" : "OVERWRITE"
      }
    },
    var.ebs_addon_enabled ? {
      "aws-ebs-csi-driver" : {
        "addon_version" : "v1.16.1-eksbuild.1",
        "resolve_conflicts" : "OVERWRITE"
      }
    } : {}
  )

  subnet_ids = concat(
    [for sub in aws_subnet.kubernetes : sub.id],
    [for sub in aws_subnet.kubernetes-private : sub.id]
  )
  vpc_id                          = data.aws_vpc.kubernetes.id
  cluster_endpoint_private_access = true
  cluster_security_group_additional_rules = {
    for group in var.api_access_security_groups :
      group.security_group => {
        description              = group.description
        type                     = "ingress"
        from_port                = 0
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = group.security_group
      }
  }

  # Self Managed Node Group(s)
  eks_managed_node_group_defaults = {
    update_launch_template_default_version = true
    iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  eks_managed_node_groups = {
    "${var.prog_name}-main" = {
      min_size     = var.autoscaling_min
      desired_size = var.autoscaling_min
      max_size     = var.autoscaling_max
      version      = var.kubernetes_version

      instance_types = var.instance_types

      vpc_security_group_ids = concat([aws_security_group.kubernetes.id], var.node_security_groups)

      tags = {
        CostCenter                                        = "${var.cost_center}"
        "k8s.io/cluster-autoscaler/enabled"               = "true"
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
      }
    }
  }

  tags = {
    CostCenter = "${var.cost_center}"
  }

}

# See https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1901
# and https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/faq.md
module "eks_auth" {
  source  = "aidanmelen/eks-auth/aws"
  version = "1.0.0"
  eks     = module.kubernetes

  map_roles = var.role_mapping
  map_users = var.user_mapping
}
