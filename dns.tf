module "eks-external-dns" {
  source  = "./external-dns"

  cluster_identity_oidc_issuer     = module.kubernetes.oidc_provider
  cluster_identity_oidc_issuer_arn = module.kubernetes.oidc_provider_arn
  irsa_role_name_prefix            = local.cluster_name
  region = var.region
  settings = {
    "podDisruptionBudget.maxUnavailable": "1"
  }

  depends_on = [module.kubernetes]
}

// rename old components to new ones
# older name
moved {
  from = module.eks-external-dns.aws_iam_policy.this[0]
  to = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_policy.irsa[0]
}

#newer name
moved {
  from = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_policy.irsa[0]
  to = module.eks-external-dns.aws_iam_policy.this
}


# older name
moved {
  from = module.eks-external-dns.aws_iam_role.this[0]
  to = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_role.irsa[0]
}
moved {
  from = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_role.irsa[0]
  to = module.eks-external-dns.aws_iam_role.this
}

# older name
moved {
  from = module.eks-external-dns.aws_iam_role_policy_attachment.this[0]
  to = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_role_policy_attachment.irsa[0]
}
# newer name
moved {
  from = module.eks-external-dns.module.addon-irsa["external-dns"].aws_iam_role_policy_attachment.irsa[0]
  to = module.eks-external-dns.aws_iam_role_policy_attachment.this
}

# older name
moved {
  from = module.eks-external-dns.helm_release.this[0]
  to = module.eks-external-dns.module.addon.helm_release.this[0]
}
# newer name
moved {
  from = module.eks-external-dns.module.addon.helm_release.this[0]
  to = module.eks-external-dns.helm_release.this
}
