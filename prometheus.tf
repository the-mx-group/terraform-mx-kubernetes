module "prometheus" {
  count = var.prometheus.enabled ? 1 : 0
  source = "./prometheus"
  metrics_namespace = coalesce(var.prometheus.namespace, "monitoring")
  alert_config = var.prometheus.alert_config
  stack_version = local.prometheus_stack_version
}
