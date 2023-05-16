module "prometheus" {
  count = var.prometheus.enabled ? 1 : 0
  source = "./prometheus"
  metrics_namespace = coalesce(var.prometheus.namespace, "monitoring")
}
