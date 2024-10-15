resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.metrics_namespace
  }
}

resource "helm_release" "prometheus" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.stack_version
  namespace  = var.metrics_namespace

  values = concat(
    [
      file("${path.module}/lens-scrapers.yaml"),
    ],
    try(
        [yamlencode(
          {
            alertmanager = {
              config = yamldecode(var.alert_config)
            }
          }
        )]
        , []
      )
  )

  dynamic "set" {
    for_each = local.prometheus_helm_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
