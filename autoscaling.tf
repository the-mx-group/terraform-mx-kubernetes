module "autoscaling" {
  count = var.autoscaling.enabled ? 1 : 0
  source = "./autoscaling"
  cluster_name = local.cluster_name
  granted_roles = { for name, group in module.kubernetes.eks_managed_node_groups : name => group.iam_role_name }
  autoscaling_version = var.autoscaling.version
  kubernetes_version = var.kubernetes_version
}
