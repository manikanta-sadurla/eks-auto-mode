resource "aws_eks_cluster" "example" {
  # Required Arguments
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }
  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_permissions
  }

  ### EKS Auto Mode ###

### When using EKS Auto Mode compute_config.enabled, kubernetes_network_config.elastic_load_balancing.enabled, 
## and storage_config.block_storage.enabled must *ALL be set to true. 
#Likewise for disabling EKS Auto Mode, all three arguments must be set to false.
  
  bootstrap_self_managed_addons = false # When EKS Auto Mode is enabled, bootstrapSelfManagedAddons must be set to false

   compute_config {
    enabled       = true
    node_pools    = [general-purpose]
    node_role_arn = aws_iam_role.eks_node_group_role.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  # Storage Config
  storage_config {
    block_storage {
      enabled = true
    }
  }

  # Optional Arguments
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Conditional Encryption Config
  dynamic "encryption_config" {
    for_each = var.encryption_key_arn != "" ? [1] : []
    content {
      provider {
        key_arn = var.encryption_key_arn
      }
      resources = ["secrets"]
    }
  }
    # Conditional Kubernetes Network Config
  # dynamic "kubernetes_network_config" {
  #   for_each = var.service_ipv4_cidr != "" ? [1] : []
  #   content {
  #     service_ipv4_cidr = var.service_ipv4_cidr
  #     ip_family         = var.ip_family
  #   }
  # }

  # Conditional Outpost Config
  dynamic "outpost_config" {
    for_each = length(var.outpost_arns) > 0 ? [1] : []
    content {
      control_plane_instance_type = var.control_plane_instance_type
      control_plane_placement {
        group_name = var.control_plane_placement_group
      }
      outpost_arns = var.outpost_arns
    }
  }

  version = var.kubernetes_version

  tags = merge(var.default_tags, var.resource_tags)
}
