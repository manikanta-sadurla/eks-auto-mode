# rabbitmq-module/outputs.tf

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.rabbitmq.name
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.rabbitmq.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.rabbitmq.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.rabbitmq.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.rabbitmq.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.rabbitmq.latest_version
}

output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}
