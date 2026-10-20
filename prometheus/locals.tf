locals {
  prometheus_helm_values = {
    # The chart's built-in kubelet ServiceMonitor replaces the old hand-written "lens" scrape jobs for the
    # kubelet and cAdvisor (see lens-scrapers.yaml). It scrapes /metrics, /metrics/cadvisor and
    # /metrics/probes (prober_probe_total: which liveness/readiness/startup probe failed for which pod)
    # with the standard labels (metrics_path, ...) that the stock recording rules and dashboards filter on.
    # kubernetesServiceMonitors.enabled is the master switch for ALL component monitors, so every other
    # component is switched off individually below: on EKS the control plane (etcd, scheduler, controller
    # manager) is not reachable, and apiserver/coredns are already covered by lens-scrapers.yaml.
    # Verified on ccg-staging 2026-10-20: all kubelet targets (Linux and Windows nodes) up, series count
    # within 1% of the lens jobs combined, stock container recording rules populated, repo dashboards fine.
    # (The 2023 workaround that disabled this was for chart 45.x.)
    "kubernetesServiceMonitors.enabled"         = true,
    "kubelet.enabled"                           = true,
    "prometheusOperator.kubeletService.enabled" = true,
    # chart default is 10s, which would triple cAdvisor ingest versus the previous 30s
    "kubelet.serviceMonitor.cAdvisorInterval" = "30s",
    "kubeApiServer.enabled"                   = false,
    "coreDns.enabled"                         = false,
    "kubeDns.enabled"                         = false,
    "kubeEtcd.enabled"                        = false,
    "kubeScheduler.enabled"                   = false,
    "kubeProxy.enabled"                       = false,
    "kubeControllerManager.enabled"           = false,
    # alert rule groups stay off (no new alert noise from this change)
    "defaultRules.rules.kubelet"                = false,
    "defaultRules.rules.kubeControllerManager"  = false,
    "defaultRules.rules.kubeProxy"              = false,
    "defaultRules.rules.kubeSchedulerAlerting"  = false,
    "defaultRules.rules.kubeSchedulerRecording" = false,
    "nodeSelector.kubernetes\\.io/os"           = "linux",
    # Pick up every ServiceMonitor, PodMonitor, Probe and PrometheusRule in any namespace, not only
    # those labeled `release: <this helm release>`, so app charts don't have to know our release name.
    "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues" = "false",
    "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"     = "false",
    "prometheus.prometheusSpec.probeSelectorNilUsesHelmValues"          = "false",
    "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"           = "false",
    # File our dashboard ConfigMaps into a Grafana folder via the `grafana_folder`
    # annotation (see dashboards.tf) instead of dumping them in General.
    "grafana.sidecar.dashboards.folderAnnotation"                   = "grafana_folder",
    "grafana.sidecar.dashboards.provider.foldersFromFilesStructure" = "true",
  }
}
