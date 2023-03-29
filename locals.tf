locals {
  cluster_name      = var.prog_name
  friendly_name     = var.name
  metrics_namespace = "metrics"
  create_vpc        = var.vpc_id == ""

  // ingress
  ingress_helm_version     = "1.4.8" // https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  ingress_manifest_version = "2.4.7" // should reference whatever the helm chart points at

  // metrics
  metrics_version = "3.9.0"

  // external dns
  external_dns_helm_version = "6.15.0" // uses https://artifacthub.io/packages/helm/bitnami/external-dns
}
