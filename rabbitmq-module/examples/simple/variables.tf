# simple/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "Name prefix for the resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where RabbitMQ will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RabbitMQ instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "Instance count must be between 1 and 5."
  }
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.volume_size >= 20 && var.volume_size <= 1000
    error_message = "Volume size must be between 20 and 1000 GB."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to RabbitMQ"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.allowed_cidr_blocks) > 0
    error_message = "At least one CIDR block must be provided."
  }
}

variable "admin_password" {
  description = "RabbitMQ admin password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

variable "enable_clustering" {
  description = "Enable RabbitMQ clustering"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
