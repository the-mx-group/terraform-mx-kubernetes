data "aws_region" "current" {}

data "http" "aws-load-balancer-controller-policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v${local.ingress_manifest_version}/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws-load-balancer-controller-policy" {
  name   = "${local.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.aws-load-balancer-controller-policy.body
}

resource "aws_iam_role" "aws-load-balancer-controller-role" {
  name = "${local.cluster_name}-aws-load-balancer-controller-role"
  assume_role_policy = templatefile("${path.module}/policy/oidc_assume_role_policy.json", {
    OIDC_ARN  = module.kubernetes.oidc_provider_arn,
    OIDC_URL  = module.kubernetes.oidc_provider,
    NAMESPACE = "kube-system",
    SA_NAME   = "aws-load-balancer-controller"
  })
  tags = {
    "ServiceAccountName"      = "aws-load-balancer-controller"
    "ServiceAccountNameSpace" = "kube-system"
  }
  depends_on = [module.kubernetes]
}

resource "aws_iam_role_policy_attachment" "aws-load-balancer-controller-role" {
  role       = aws_iam_role.aws-load-balancer-controller-role.name
  policy_arn = aws_iam_policy.aws-load-balancer-controller-policy.arn
  depends_on = [aws_iam_role.aws-load-balancer-controller-role]
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws-load-balancer-controller-role.arn
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = local.ingress_helm_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.kubernetes.id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name = "podDisruptionBudget.maxUnavailable"
    value = "1"
  }

  depends_on = [
    module.kubernetes
  ]
}
