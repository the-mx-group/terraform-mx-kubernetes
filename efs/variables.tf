variable "cluster_name" {
  type        = string
  description = "The name of this Kubernetes cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version in use on the cluster"
}

variable "oidc_arn" {
  type        = string
  description = "The ARN for this cluster's OIDC endpoint"
}

variable "oidc_url" {
  type        = string
  description = "The URL for this cluster's OIDC endpoint"
}

variable "region_code" {
  type        = string
  description = "The region code for this cluster"
}
