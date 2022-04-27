locals {
  cluster_name      = var.prog_name
  friendly_name     = var.name
  metrics_namespace = "metrics"
  create_vpc        = var.vpc_id == ""

  // ingress
  ingress_helm_version     = "1.4.1"
  ingress_manifest_version = "2.4.1" // should reference whatever the helm chart points at
}
