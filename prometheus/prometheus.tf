resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.metrics_namespace
  }
}

resource "helm_release" "prometheus" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = local.prometheus_stack_version
  namespace  = var.metrics_namespace

  values = [
    file("${path.module}/lens-scrapers.yaml"),
  ]

  dynamic "set" {
    for_each = local.prometheus_helm_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
