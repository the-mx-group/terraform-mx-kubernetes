module "prometheus" {
  count = var.prometheus.enabled ? 1 : 0
  source = "./prometheus"
  metrics_namespace = coalesce(var.prometheus.namespace, "monitoring")
  alert_config = var.prometheus.alert_config
  stack_version = local.prometheus_stack_version
  enable_windows = anytrue([
    for ng in var.node_groups : strcontains(lower(ng.ami_type), "windows")
  ])
}
