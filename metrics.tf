###
# Install these formulas directly into cluster without checking specs in Terraform
###

resource "kubernetes_namespace" "metrics" {
  metadata {
    name = local.metrics_namespace
  }
}

resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = local.metrics_version
  namespace  = local.metrics_namespace
}
