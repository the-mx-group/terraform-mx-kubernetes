module "efs" {
  count = var.efs_enabled ? 1 : 0
  source = "./efs"
  cluster_name = local.cluster_name
  kubernetes_version = var.kubernetes_version
  region_code = data.aws_region.current.region
  oidc_arn = module.kubernetes.oidc_provider_arn
  oidc_url = module.kubernetes.oidc_provider
}
