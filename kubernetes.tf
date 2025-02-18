data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}


#actually provision the kubernetes cluster
module "kubernetes" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "20.26.0" // https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  cluster_name                   = local.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true
  authentication_mode            = var.authentication_mode
  #kms_key_enable_default_policy = false # for v19 compat
  cluster_addons = merge(
    {
      "vpc-cni" : {
        "resolve_conflicts_on_create" : "OVERWRITE",
        "configuration_values" : jsonencode({
          "env" : {
            "ENABLE_PREFIX_DELEGATION" : "true"
          }
        })
      },
      "coredns" : {
        "resolve_conflicts_on_create" = "OVERWRITE"
      },
      "kube-proxy" : {
        "resolve_conflicts_on_create" = "OVERWRITE"
      }
    },
    var.ebs_addon_enabled ? {
      "aws-ebs-csi-driver" : {
        "resolve_conflicts_on_create" : "OVERWRITE"
      }
    } : {},
    var.authentication_mode != "CONFIG_MAP" ? {
      "eks-pod-identity-agent" : {}
    } : {},
  )

  kms_key_administrators = concat(var.kms_key_administrators, [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
    data.aws_iam_session_context.current.issuer_arn
  ])

  enable_cluster_creator_admin_permissions = var.authentication_mode != "CONFIG_MAP" # enable creator admin permissions as long as we're not in config map mode

  access_entries = var.access_entries

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
    iam_role_additional_policies = {
      "ssm-managed-instance" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    "${var.prog_name}-main" = {
      min_size     = var.autoscaling_min
      desired_size = var.autoscaling_min
      max_size     = var.autoscaling_max
      version      = var.kubernetes_version

      instance_types = var.instance_types

      vpc_security_group_ids = concat([aws_security_group.kubernetes.id], var.node_security_groups)

      tags = merge(var.tags, {
        CostCenter                                        = "${var.cost_center}"
        "k8s.io/cluster-autoscaler/enabled"               = "true"
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "true"
      })
    }
  }

  tags = merge(var.tags, {
    CostCenter = "${var.cost_center}" // don't let them override CostCenter
  })

}

module "eks_aws_auth" {
  source                    = "terraform-aws-modules/eks/aws//modules/aws-auth" // doubleslash here is intentional; this is a submodule
  version                   = "~> 20.0"
  manage_aws_auth_configmap = var.authentication_mode == "API" ? false : true
  aws_auth_roles = concat(var.role_mapping, [
    {
      rolearn  = module.kubernetes.eks_managed_node_groups["${var.prog_name}-main"].iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ])
  aws_auth_users = var.user_mapping
}

# make life easier for migration
moved {
  from = module.eks_auth.kubernetes_config_map_v1_data.aws_auth[0]
  to   = module.eks_aws_auth.kubernetes_config_map_v1_data.aws_auth[0]
}
