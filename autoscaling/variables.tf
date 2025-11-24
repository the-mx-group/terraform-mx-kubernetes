variable "cluster_name" {
  type        = string
  description = "The programmatic name for this cluster"
}
variable "granted_roles" {
  type = map(string)
  description = "The ARNs of roles which should get access to scale the cluster. Generally, this would be all the roles used as instance profiles on your node groups"
}
variable "autoscaling_version" {
  type        = string
  description = "The autoscaling version to use"
}
variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version in use on the cluster.  Affects which APIs we use to create resources"
}
variable "cluster_oidc_endpoint" {
  type        = string
  description = "The OIDC endpoint for the cluster"
}
variable "cluster_oidc_arn" {
  type        = string
  description = "The OIDC provider ARN for the cluster"
}
