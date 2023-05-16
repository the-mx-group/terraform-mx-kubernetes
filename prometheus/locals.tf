locals {
  prometheus_stack_version = "45.28.0"
  prometheus_helm_values = {
    "kubernetesServiceMonitors.enabled" = false,
    "kubeControllerManager.enabled" = false,
    "defaultRules.rules.kubeControllerManager" = false,
    "kubeProxy.enabled" = false,
    "defaultRules.rules.kubeProxy" = false,
    "kubelet.enabled" = false,
    "defaultRules.rules.kubelet" = false,
    "defaultRules.rules.kubeSchedulerAlerting" = false,
    "defaultRules.rules.kubeSchedulerRecording" = false,
  }
}
