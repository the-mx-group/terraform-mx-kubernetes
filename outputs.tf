output "vpc_id" {
  value = data.aws_vpc.kubernetes.id
}
output "vpc_cidr" {
  value = data.aws_vpc.kubernetes.cidr_block
  description = "The ID of the security group created for nodes"
}
output "security_group" {
  value = aws_security_group.kubernetes.id
  description = "The ID of the security group created for nodes"
}
