output "vpc_id" {
  value = data.aws_vpc.kubernetes.id
}
output "vpc_cidr" {
  value = data.aws_vpc.kubernetes.cidr_block
  description = "The ID of the security group created for nodes"
}
output "oidc_arn" {
  value = module.kubernetes.oidc_provider_arn
  description = "ARN for the OIDC provider for this cluster"
}
output "cluster_id" {
  value = module.kubernetes.cluster_name
  description = "Cluster ID"
}
output "cluster_endpoint" {
  value = module.kubernetes.cluster_endpoint
  description = "API endpoint for cluster administration"
}
output "cluster_certificate_authority_data" {
  value = module.kubernetes.cluster_certificate_authority_data
  description = "CA data for cluster API connection"
}
output "security_group" {
  value = aws_security_group.kubernetes.id
  description = "The ID of the security group created for nodes"
}
output "public_subnet_ids" {
  value = [
    for net in aws_subnet.kubernetes : net.id
  ]
}
