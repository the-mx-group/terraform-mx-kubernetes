module "karpenter" {
  count  = var.karpenter.enabled ? 1 : 0
  source = "./karpenter"

  cluster_name                      = local.cluster_name
  cluster_endpoint                  = module.kubernetes.cluster_endpoint
  chart_version                     = coalesce(var.karpenter.version, local.karpenter_version)
  node_iam_role_additional_policies = var.karpenter.node_iam_role_additional_policies
  settings                          = coalesce(var.karpenter.settings, {})
  tags                              = var.tags

  depends_on = [module.kubernetes]
}
