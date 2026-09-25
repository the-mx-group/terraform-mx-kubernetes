output "node_iam_role_name" {
  value       = module.karpenter.node_iam_role_name
  description = "Name of the IAM role created for Karpenter-managed nodes. Reference this from your EC2NodeClass."
}

output "node_iam_role_arn" {
  value       = module.karpenter.node_iam_role_arn
  description = "ARN of the IAM role created for Karpenter-managed nodes"
}

output "instance_profile_name" {
  value       = module.karpenter.instance_profile_name
  description = "Name of the instance profile created for Karpenter-managed nodes. Reference this from your EC2NodeClass."
}

output "queue_name" {
  value       = module.karpenter.queue_name
  description = "Name of the SQS queue used for interruption handling"
}
