variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster Karpenter will manage nodes for"
}

variable "cluster_endpoint" {
  type        = string
  description = "The API endpoint of the EKS cluster, passed through to the Karpenter controller's settings.clusterEndpoint"
}

variable "chart_version" {
  type        = string
  description = "The version of the karpenter/karpenter-crd Helm charts to install"
}

variable "node_iam_role_additional_policies" {
  type        = map(string)
  default     = {}
  description = "Additional IAM policies to attach to the Karpenter node IAM role, in {'static_name' = 'policy_arn'} format"
}

variable "settings" {
  type        = map(string)
  default     = {}
  description = "Additional Helm `set` values passed through to the karpenter chart"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to apply to resources created by this module"
}
