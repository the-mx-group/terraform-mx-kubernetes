module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.25.0" // pinned to match the version used by the root `kubernetes` module

  cluster_name = var.cluster_name

  # controller access is granted via EKS Pod Identity, not IRSA
  node_iam_role_additional_policies = var.node_iam_role_additional_policies

  tags = var.tags
}
