locals {
  cluster_name      = var.prog_name
  friendly_name     = var.name
  metrics_namespace = "metrics"
  create_vpc        = var.vpc_id == null
  create_nat_gateway = length(var.private_subnets.networks) > 0 && var.private_subnets.nat_gateway.gateway_id == null

  // ingress
  ingress_helm_version     = "3.3.0" // https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  ingress_manifest_version = "3.3.0" // should reference whatever the helm chart points at, since jan 2026 they should match

  // metrics
  metrics_version = "3.13.0"   // latest helm chart from https://github.com/kubernetes-sigs/metrics-server/releases

  // prometheus
  prometheus_stack_version = "85.0.3" // https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack/

}
