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
