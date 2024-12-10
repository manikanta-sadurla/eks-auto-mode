provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79"
    }
  }
}


# locals {
#   name            = "ex-${basename(path.cwd)}"
#   cluster_version = "1.31"
#   region          = "us-west-2"

#   vpc_cidr = "10.0.0.0/16"
#   azs      = slice(data.aws_availability_zones.available.names, 0, 3)

#   tags = {
#     Test       = local.name
#     GithubRepo = "terraform-aws-eks"
#     GithubOrg  = "terraform-aws-modules"
#   }
# }

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks?ref=v20.31.1"


  cluster_name                   = "terraform-reg"
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = "vpc-0e6c09980580ecbf6"
  subnet_ids = ["subnet-066d0c78479b72e77", "subnet-064b80a494fed9835"]

   eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2_x86_64"
      instance_types = ["m6i.large"]

      min_size = 2
      max_size = 5
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
    }
  }

  tags = {
    Test       = "Created by Terraform-REG"
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}
