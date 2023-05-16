locals {
  cluster_name      = var.prog_name
  friendly_name     = var.name
  metrics_namespace = "metrics"
  create_vpc        = var.vpc_id == ""

  // ingress
  ingress_helm_version     = "1.5.2" // https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  ingress_manifest_version = "2.5.1" // should reference whatever the helm chart points at

  // metrics
  metrics_version = "3.10.0"   // latest helm chart from https://github.com/kubernetes-sigs/metrics-server/releases

  // external dns
  external_dns_helm_version = "6.20.1" // uses https://artifacthub.io/packages/helm/bitnami/external-dns

}
