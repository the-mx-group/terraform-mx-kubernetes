module "autoscaling" {
  count = var.enable_autoscaler ? 1 : 0
  source = "./autoscaling"
  cluster_name = local.cluster_name
  granted_roles = [ for name, group in module.kubernetes.eks_managed_node_groups : group.iam_role_arn ]
  autoscaling_version = var.autoscaling_version
}
