output "rabbitmq_asg_name" {
  description = "Name of the RabbitMQ Auto Scaling Group"
  value       = module.rabbitmq.asg_name
}

output "rabbitmq_security_group_id" {
  description = "ID of the RabbitMQ security group"
  value       = module.rabbitmq.security_group_id
}

output "rabbitmq_iam_role_arn" {
  description = "ARN of the RabbitMQ IAM role"
  value       = module.rabbitmq.iam_role_arn
}