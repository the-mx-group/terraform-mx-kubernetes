module "prometheus" {
  count = var.prometheus.enabled ? 1 : 0
  source = "./prometheus"
  metrics_namespace = coalesce(var.prometheus.namespace, "monitoring")
  alert_config = var.prometheus.alert_config
  stack_version = local.prometheus_stack_version
  cluster_name = local.cluster_name
  enable_autoscaler_alerts = var.autoscaling.enabled
  enable_windows = anytrue([
    for ng in var.node_groups : strcontains(lower(ng.ami_type), "windows")
  ])
}
