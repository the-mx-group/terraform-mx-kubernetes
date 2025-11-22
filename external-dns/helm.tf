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

  set = [
    {
      name  = "podDisruptionBudget.maxUnavailable"
      value = "1"
    },
    {
      name  = "rbac.create"
      value = "true"
    },
    {
      name  = "provider.name"
      value = "aws"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${aws_iam_role.this.arn}"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "podDisruptionBudget.maxUnavailable"
      value = "1"
    }
  ]
}
