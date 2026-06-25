locals {
  prometheus_helm_values = {
    "kubernetesServiceMonitors.enabled"         = false,
    "kubeControllerManager.enabled"             = false,
    "defaultRules.rules.kubeControllerManager"  = false,
    "kubeProxy.enabled"                         = false,
    "defaultRules.rules.kubeProxy"              = false,
    "kubelet.enabled"                           = false,
    "defaultRules.rules.kubelet"                = false,
    "defaultRules.rules.kubeSchedulerAlerting"  = false,
    "defaultRules.rules.kubeSchedulerRecording" = false,
    "prometheusOperator.kubeletService.enabled" = false,
    "nodeSelector.kubernetes\\.io/os"           = "linux",
    # File our dashboard ConfigMaps into a Grafana folder via the `grafana_folder`
    # annotation (see dashboards.tf) instead of dumping them in General.
    "grafana.sidecar.dashboards.folderAnnotation"                   = "grafana_folder",
    "grafana.sidecar.dashboards.provider.foldersFromFilesStructure" = "true",
  }
}
