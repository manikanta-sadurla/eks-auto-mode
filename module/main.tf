# resource "aws_eks_cluster" "example" {
#   # Required Arguments
#   name     = var.cluster_name
#   role_arn = aws_iam_role.eks_cluster_role.arn

#   vpc_config {
#     subnet_ids            = var.subnet_ids
#     security_group_ids    = var.security_group_ids
#     endpoint_public_access = var.endpoint_public_access
#     endpoint_private_access = var.endpoint_private_access
#     public_access_cidrs    = var.public_access_cidrs
#   }

#   # Optional Arguments
#   enabled_cluster_log_types = var.enabled_cluster_log_types

#   encryption_config {
#     provider {
#       key_arn = var.encryption_key_arn
#     }
#     resources = ["secrets"]
#   }

#   kubernetes_network_config {
#     service_ipv4_cidr = var.service_ipv4_cidr
#     ip_family         = var.ip_family
#   }

#   access_config {
#     authentication_mode                   = var.authentication_mode
#     bootstrap_cluster_creator_admin_permissions = var.bootstrap_permissions
#   }

#   upgrade_policy {
#     support_type = var.upgrade_support_type
#   }

#   outpost_config {
#     control_plane_instance_type = var.control_plane_instance_type
#     control_plane_placement {
#       group_name = var.control_plane_placement_group
#     }
#     outpost_arns = var.outpost_arns
#   }

# #   zonal_shift_config {
# #     enabled = var.zonal_shift_enabled
# #   }

#   bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

#   version = var.kubernetes_version

#   tags = {
#   Environment = "poc"
#   Project     = "play-hq"
# }
# }

resource "aws_eks_cluster" "example" {
  # Required Arguments
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids            = var.subnet_ids
    security_group_ids    = var.security_group_ids
    endpoint_public_access = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs    = var.public_access_cidrs
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
  dynamic "kubernetes_network_config" {
    for_each = var.service_ipv4_cidr != "" ? [1] : []
    content {
      service_ipv4_cidr = var.service_ipv4_cidr
      ip_family         = var.ip_family
    }
  }

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

  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons

  version = var.kubernetes_version

  tags = merge(var.default_tags, var.resource_tags)
}
