resource "helm_release" "karpenter_crd" {
  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = var.chart_version
  namespace  = "kube-system"
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.chart_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      serviceAccount = {
        name = module.karpenter.service_account
      }
      settings = {
        clusterName       = var.cluster_name
        clusterEndpoint   = var.cluster_endpoint
        interruptionQueue = module.karpenter.queue_name
      }
    })
  ]

  set = [
    for key, value in var.settings : {
      name  = key
      value = value
    }
  ]

  depends_on = [helm_release.karpenter_crd]
}
