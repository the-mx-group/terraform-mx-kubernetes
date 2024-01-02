variable "name" {
  type        = string
  description = "The user-friendly name for this cluster"
}

variable "prog_name" {
  type        = string
  description = "A software-friendly name (no spaces, special characters, uppercase, etc)"
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version to deploy"
}

variable "autoscaling_version" {
  type        = string
  default     = ""
  description = "The autoscaling version to deploy, if enabled"
}

variable "instance_types" {
  type        = list(string)
  description = "The instance types to provision (e.g., t3.medium)"
}

variable "autoscaling" {
  type = object({
    enabled = bool
    version = string
  })
  default = { enabled : false, version = "" }
  validation {
    condition     = var.autoscaling.enabled == false || length(var.autoscaling.version) > 2
    error_message = "When enabling autoscaling, you must specify a version that works with your Kubernetes version.  See https://github.com/kubernetes/autoscaler/releases?q=v1.22&expanded=true for details."
  }
}

variable "autoscaling_min" {
  type        = number
  description = "The minimum number of cluster nodes available"
}
variable "autoscaling_max" {
  type        = number
  description = "The minimum number of cluster nodes to provision"
}

variable "enable_efs" {
  type        = bool
  default     = false
  description = "DEPRECATED: use efs_enabled.  Whether to deploy the EFS CSI module.  Note that your cluster must contian at least 2 nodes to enable this module."
}

variable "efs_enabled" {
  type        = bool
  default     = false
  description = "Whether to deploy the EFS CSI module.  Note that your cluster must contian at least 2 nodes to enable this module."
}

variable "cost_center" {
  type        = string
  default     = "Kubernetes"
  description = "A Cost Center tag to apply to all created resources"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "The VPC to use for this cluster.  If not provided, one will be created."
}

variable "vpc_cidr" {
  type        = string
  default     = ""
  description = "If creating a VPC, defines the CIDR block to use"
}

variable "public_subnets" {
  type = list(object({
    az         = string
    cidr_block = string
  }))
  description = "Public subnets to create and use for this cluster."
}

variable "private_subnets" {
  type = object({
    networks = list(object({
      az         = string
      cidr_block = string

    }))
    nat_gateway = object({
      id         = optional(string)
      cidr_block = optional(string)
      az         = optional(string)
    })
  })
  default     = { networks = [], nat_gateway = { id = "", cidr_block = "", az = "" } }
  description = "Private subnets to create and use for this cluster."
  validation {
    condition     = length(var.private_subnets.networks) == 0 || var.private_subnets.nat_gateway.id != "" || ( var.private_subnets.nat_gateway.cidr_block != null && var.private_subnets.nat_gateway.az != null)
    error_message = "value of nat_gateway.id or az/cidr_block must be specified when private_subnets are specified"
  }
}

variable "user_mapping" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = "IAM User ARNs to map to cluster users"
}

variable "role_mapping" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "IAM Role ARNs to map to cluster roles"
}

variable "node_security_groups" {
  type        = list(string)
  description = "Extra security groups to attach to nodes"
  default     = []
}

variable "full_access_ip_blocks" {
  type        = list(string)
  description = "IPs to allow in to all SGs created by this recipe"
  default     = []
}

variable "api_access_security_groups" {
  type = list(object({
    description    = string
    security_group = string
  }))
  description = "Security groups that should be able to access the internal Kubernetes API"

  default = []
}

variable "kms_key_administrators" {
  type        = list(string)
  default     = []
  description = "ARNs of users who should be able to administer the KMS key used to encrypt secrets at rest in the cluster"
}

variable "ebs_addon_enabled" {
  type        = bool
  description = "Should the EBS addon be installed"
  default     = false
}

variable "prometheus" {
  type = object({
    enabled = bool
    namespace = optional(string)
    alert_config = optional(string)
  })
  default = { enabled : false }
  description = <<-EOT
    Should Prometheus be configured for the instance. Default is false.
    If enabled, you can optionally specify a namespace and alert_config.
    * namespace is the Kubernetes namespace to create all resources
    * alert_config should be a YAML string that can be decoded by the Prometheus alertmanager.
      A default configuration is provided, so you only need to pass parts of the config that you want to change (for example, a receivers array)
      See https://prometheus.io/docs/alerting/latest/configuration/ for details.
    EOT
}
