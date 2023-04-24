module "eks-external-dns" {
  source  = "lablabs/eks-external-dns/aws"
  version = "1.1.1"

  cluster_identity_oidc_issuer     = module.kubernetes.oidc_provider
  cluster_identity_oidc_issuer_arn = module.kubernetes.oidc_provider_arn
  irsa_role_name_prefix            = local.cluster_name
  helm_chart_version               = local.external_dns_helm_version
  settings = {
    "podDisruptionBudget.maxUnavailable": "1"
  }
}
