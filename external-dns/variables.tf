
variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OIDC Identity issuer for the cluster (required for IRSA)."
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a Service Account (required for IRSA)."
}

variable "irsa_role_name_prefix" {
  type        = string
  description = "IRSA role name prefix."
}

variable "region" {
  type        = string
  description = "AWS region where EKS is installed."
}

variable "settings" {
  type        = map(any)
  default     = null
  description = "Additional Helm sets which will be passed to the Helm chart values. Defaults to `{}`."
}
