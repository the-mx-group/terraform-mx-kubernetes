locals {
  cluster_name      = var.prog_name
  friendly_name     = var.name
  metrics_namespace = "metrics"
  create_vpc        = var.vpc_id == ""
  create_nat_gateway = var.private_subnets.nat_gateway.id == "" && length(var.private_subnets.networks) > 0

  // ingress
  ingress_helm_version     = "1.6.2" // https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  ingress_manifest_version = "2.6.2" // should reference whatever the helm chart points at

  // metrics
  metrics_version = "3.11.0"   // latest helm chart from https://github.com/kubernetes-sigs/metrics-server/releases

  // external dns
  external_dns_helm_version = "6.28.6" // uses https://artifacthub.io/packages/helm/bitnami/external-dns

}
