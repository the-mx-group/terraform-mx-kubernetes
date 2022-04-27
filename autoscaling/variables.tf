variable "cluster_name" {
  type        = string
  description = "The programmatic name for this cluster"
}
variable "granted_roles" {
  type = list(string)
  description = "The ARNs of roles which should get access to scale the cluster. Generally, this would be all the roles used as instance profiles on your node groups"
}
variable "autoscaling_version" {
  type        = string
  description = "The autoscaling version to use"
}
