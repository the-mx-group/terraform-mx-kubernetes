module "eks-external-dns" {
  source  = "lablabs/eks-external-dns/aws"
  version = "0.9.0"

  cluster_identity_oidc_issuer     = module.kubernetes.oidc_provider
  cluster_identity_oidc_issuer_arn = module.kubernetes.oidc_provider_arn
  k8s_irsa_role_name_prefix        = local.cluster_name
  helm_chart_version               = "6.2.4" // uses https://artifacthub.io/packages/helm/bitnami/external-dns
}
