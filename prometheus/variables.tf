variable "metrics_namespace" {
  type = string
  description = "Namespace to install metrics server into"
}

variable "alert_config" {
  type = string
  description = "Extra configuration for alerting"
  default = null
}

variable "stack_version" {
  type = string
  description = "Version of the prometheus stack to install"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name, used in the text of alerts so the source cluster is clear in emails"
  default     = ""
}

variable "enable_autoscaler_alerts" {
  type        = bool
  description = "Whether to add alerts for cluster-autoscaler health and node-count headroom"
  default     = false
}

variable "enable_windows" {
  type = bool
  description = "Whether to enable windows node support in prometheus"
  default = false
}
