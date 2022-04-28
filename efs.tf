module "efs" {
  count = (var.enable_efs && var.autoscaling_min >= 2) ? 1 : 0
  source = "./efs"
  cluster_name = local.cluster_name
  region_code = data.aws_region.current.name
  oidc_arn = module.kubernetes.oidc_provider_arn
  oidc_url = module.kubernetes.oidc_provider
}
