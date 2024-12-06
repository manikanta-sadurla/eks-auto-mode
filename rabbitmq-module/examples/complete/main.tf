provider "aws" {
  region = var.aws_region
}

module "rabbitmq" {
  source = "../../"

  name               = "app"
  environment        = "prod"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks
  
  instance_type     = "t3.large"
  instance_count    = 3
  volume_size       = 50
  
  admin_user        = var.admin_user
  admin_password    = var.admin_password
  
  enable_clustering = true
  
  alarm_actions     = [var.sns_topic_arn]
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  }
}