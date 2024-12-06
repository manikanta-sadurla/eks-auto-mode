variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where RabbitMQ will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RabbitMQ cluster"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to RabbitMQ"
  type        = list(string)
}

variable "admin_user" {
  description = "RabbitMQ admin username"
  type        = string
}

variable "admin_password" {
  description = "RabbitMQ admin password"
  type        = string
  sensitive   = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}