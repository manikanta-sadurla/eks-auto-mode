# simple/main.tf
provider "aws" {
  region = var.aws_region
}

module "rabbitmq" {
  source = "../../"

  name        = var.name
  environment = var.environment
  ami_id = "ami-0453ec754f44f9a4a"
  
  vpc_id         = var.vpc_id
  subnet_ids     = var.subnet_ids
  
  instance_type  = var.instance_type
  instance_count = var.instance_count
  volume_size    = var.volume_size
  
  allowed_cidr_blocks = var.allowed_cidr_blocks
  admin_password      = var.admin_password
  
  enable_clustering = var.enable_clustering

  tags = var.tags
}
