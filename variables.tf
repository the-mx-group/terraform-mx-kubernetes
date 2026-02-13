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

variable "node_groups" {
  type = list(object({
    name         = string
    min_nodes    = number
    max_nodes    = number
    disk_size_gb = number
    ami_type     = string # See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values
    instance_type = optional(string)
    spot_options = optional(object({
      block_duration_minutes         = optional(number)
      instance_interruption_behavior = optional(string)
      max_price                      = optional(string)
      spot_instance_type             = optional(string)
      valid_until                    = optional(string)
    }))
  }))
  description = "Node groups to create in this cluster.  At least one node group must be specified.  Within each node group, either a spot configuration or an instance type must be specified."
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
  default     = null
  description = "The VPC to use for this cluster.  If not provided, one will be created."
}

variable "vpc_cidr" {
  type        = string
  default     = null
  description = "If creating a VPC, defines the CIDR block to use"
}

variable "public_subnets" {
  type = list(object({
    az         = string
    cidr_block = string
  }))
  default     = []
  description = "Public subnets to create and use for this cluster."
}

variable "private_subnets" {
  type = object({
    networks = list(object({
      az         = string
      cidr_block = string
    }))
    nat_gateway = object({
      gateway_id = optional(string)
      cidr_block = optional(string)
      az         = optional(string)
    })
  })
  default     = { networks = [], nat_gateway = { id = null, cidr_block = null, az = null } }
  description = <<EOT
    Private subnets to create and use for this cluster.
    If you specify private subnets, you must either provide a NAT Gateway ID or a cidr block and AZ for us to create one.
    EOT
  validation {
    condition     = length(var.private_subnets.networks) == 0 || var.private_subnets.nat_gateway.gateway_id != null || (var.private_subnets.nat_gateway.cidr_block != null && var.private_subnets.nat_gateway.az != null)
    error_message = "value of nat_gateway.id or az/cidr_block must be specified when private_subnets are specified"
  }
}

variable "authentication_mode" {
  type        = string
  default     = "CONFIG_MAP"
  description = "AWS has introduced a new API-based auth model.  Change this variable to API_AND_CONFIG_MAP to use it side-by-side with configmap, or API to use it exclusively.  Note that this can't be undone - you can't go backwards in this progression."
}

variable "access_entries" {
  type        = any
  default     = {}
  description = <<EODOC
  Entries to add to the AWS cluster policy list.  Only makes sense if the authentication mode is API_AND_CONFIG_MAP or API.  For example:
  access_entries = {
    mx_admin = {
      principal_arn = aws_iam_role.mx_admins.arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
EODOC

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
    enabled      = bool
    namespace    = optional(string)
    alert_config = optional(string)
  })
  default     = { enabled : false }
  description = <<-EOT
    Should Prometheus be configured for the instance. Default is false.
    If enabled, you can optionally specify a namespace and alert_config.
    * namespace is the Kubernetes namespace to create all resources
    * alert_config should be a YAML string that can be decoded by the Prometheus alertmanager.
      A default configuration is provided, so you only need to pass parts of the config that you want to change (for example, a receivers array)
      See https://prometheus.io/docs/alerting/latest/configuration/ for details.
    EOT
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to apply to all resources"
}

variable "extra_addons" {
  type        = map(any)
  default     = null
  description = <<-EOT
    A map of extra addons to add to the cluster.  This is passed directly to the eks module, so refer to their documentation for details: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#addons

    Note that some addons are either provided automatically or are configurable with flags. These include:
      * vpc-cni (always on, automatic)
      * coredns (always on, automatic)
      * kube-proxy (always on, automatic)
      * eks-pod-identity-agent (automatic IF authentication_mode is not CONFIG_MAP)
      * aws-ebs-csi-driver (configurable with ebs_addon_enabled)

    Example:
    extra_addons = {
      "aws-secrets-store-csi-driver-provider" : {
        "resolve_conflicts_on_create" = "OVERWRITE"
      },
    }
    EOT
}
