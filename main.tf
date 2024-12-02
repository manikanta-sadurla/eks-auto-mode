provider "aws" {
  region = var.region
}

module "tags" {
  source      = "sourcefuse/arc-tags/aws"
  version     = "1.2.2"
  environment = var.environment
  project     = "arc"

  extra_tags = {
    Repo = "github.com/sourcefuse/terraform-aws-arc-eks"
  }
}

module "eks_cluster" {
  source                    = "sourcefuse/arc-eks/aws"
  version                   = "5.0.5"
  environment               = var.environment
  name                      = var.name
  namespace                 = var.namespace
  desired_size              = var.desired_size
  instance_types            = var.instance_types
  kubernetes_namespace      = var.kubernetes_namespace
  create_node_group         = true
  max_size                  = var.max_size
  min_size                  = var.min_size
  subnet_ids                = data.aws_subnets.private.ids
  region                    = var.region
  vpc_id                    = data.aws_vpc.vpc.id
  enabled                   = true
  kubernetes_version        = var.kubernetes_version
  apply_config_map_aws_auth = true
  kube_data_auth_enabled    = true
  kube_exec_auth_enabled    = true
  #  csi_driver_enabled        = var.csi_driver_enabled
  map_additional_iam_roles = var.map_additional_iam_roles
  allowed_security_groups  = ["sg-02969d9cf1e07897c"]
}


# Fetch the existing EKS cluster information
data "aws_eks_cluster" "example" {
  name = "arc-poc-cluster"
}



resource "null_resource" "eks_update_cluster_config" {
  provisioner "local-exec" {
    command = "aws eks update-cluster-config --name ${var.cluster_name} --compute-config enabled=true --kubernetes-network-config '{\"elasticLoadBalancing\":{\"enabled\": true}}' --storage-config '{\"blockStorage\":{\"enabled\": true}}'"
  }

  triggers = {
    cluster_name = var.cluster_name
  }
}


### Manually added API Access in EKS
