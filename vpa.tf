###
# Install the Vertical Pod Autoscaler directly into the cluster without checking specs in Terraform
###

resource "helm_release" "vpa" {
  count = var.vpa.enabled ? 1 : 0

  name       = "vpa"
  repository = "https://kubernetes.github.io/autoscaler" // official chart, https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/charts/vertical-pod-autoscaler
  chart      = "vertical-pod-autoscaler"
  version    = coalesce(var.vpa.version, local.vpa_version)
  namespace  = coalesce(var.vpa.namespace, "kube-system")

  set = concat(
    [
      {
        name  = "recommender.nodeSelector.kubernetes\\.io/os"
        value = "linux"
      },
      {
        name  = "updater.nodeSelector.kubernetes\\.io/os"
        value = "linux"
      },
      {
        name  = "admissionController.nodeSelector.kubernetes\\.io/os"
        value = "linux"
      },
    ],
    [
      for key, value in coalesce(var.vpa.settings, {}) : {
        name  = key
        value = value
      }
    ]
  )

  depends_on = [module.kubernetes]
}
