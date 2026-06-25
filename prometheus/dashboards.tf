# Default Grafana dashboards, shipped as ConfigMaps that the kube-prometheus-stack
# grafana sidecar auto-discovers (it watches `grafana_dashboard=1` in ALL namespaces).
# Each *.json under ./dashboards becomes one dashboard, filed under the
# "Cluster Health" folder in Grafana via the folder annotation.
resource "kubernetes_config_map_v1" "dashboards" {
  for_each = fileset("${path.module}/dashboards", "*.json")

  metadata {
    name      = "mx-dashboard-${replace(each.value, ".json", "")}"
    namespace = var.metrics_namespace
    labels = {
      grafana_dashboard = "1"
    }
    annotations = {
      grafana_folder = "Cluster Health"
    }
  }

  data = {
    (each.value) = file("${path.module}/dashboards/${each.value}")
  }

  depends_on = [kubernetes_namespace_v1.monitoring]
}
