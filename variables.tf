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

variable "autoscaling_min" {
  type        = number
  description = "The minimum number of cluster nodes available"
}
variable "autoscaling_max" {
  type        = number
  description = "The minimum number of cluster nodes to provision"
}

variable "enable_autoscaler" {
  type        = bool
  default     = false
  description = "Whether to deploy the Cluster Autoscaler"
}

variable "enable_efs" {
  type        = bool
  default     = false
  description = "Whether to deploy the EFS CSI module"
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
  type = list(object({
    az         = string
    cidr_block = string
  }))
  default = []
  description = "Private subnets to create and use for this cluster."
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

variable "full_access_ip_blocks" {
  type        = list(string)
  description = "IPs to allow in to all SGs created by this recipe"
}
