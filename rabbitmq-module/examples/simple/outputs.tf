# simple/outputs.tf
output "rabbitmq_asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.rabbitmq.asg_name
}

output "rabbitmq_security_group_id" {
  description = "ID of the RabbitMQ security group"
  value       = module.rabbitmq.security_group_id
}

output "rabbitmq_iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.rabbitmq.iam_role_arn
}

output "rabbitmq_kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.rabbitmq.kms_key_arn
}

output "rabbitmq_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = module.rabbitmq.instance_profile_name
}

output "rabbitmq_launch_template_id" {
  description = "ID of the launch template"
  value       = module.rabbitmq.launch_template_id
}
