locals {
  prometheus_stack_version = "45.28.0"
  prometheus_helm_values = {
    "kubernetesServiceMonitors.enabled" = false,
  }
}
