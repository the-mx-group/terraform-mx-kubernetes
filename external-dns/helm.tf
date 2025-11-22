resource "helm_release" "this" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.19.0"
  namespace  = "kube-system"

  values = [<<-EOT
  env:
    - name: AWS_DEFAULT_REGION
      value: "${var.region}"
  EOT
  ]

  set {
    name  = "podDisruptionBudget.maxUnavailable"
    value = "1"
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
  set {
    name  = "provider.name"
    value = "aws"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.this.arn}"
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
  set {
    name  = "podDisruptionBudget.maxUnavailable"
    value = "1"
  }
}
