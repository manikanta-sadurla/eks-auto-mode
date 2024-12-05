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

    compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.eks_node_group_role.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

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



#### Enabling EKS Auto Mode ##
# resource "null_resource" "eks_update_cluster_config" {
#   provisioner "local-exec" {
#     command = "aws eks update-cluster-config --name ${var.cluster_name} --compute-config enabled=true --kubernetes-network-config '{\"elasticLoadBalancing\":{\"enabled\": true}}' --storage-config '{\"blockStorage\":{\"enabled\": true}}' --node-role-arn ${aws_iam_role.eks_node_group_role.arn} --node-pools '[\"general-purpose\", \"system\"]'"
#   }

#   triggers = {
#     cluster_name = var.cluster_name
#   }
#   depends_on = [ aws_eks_cluster.example ]
# }


# Fetch AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Create the Kubernetes ConfigMap dynamically
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([
      for user in var.user_definitions : {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.user_name}"
        username = user.user_name
        groups   = user.groups
      }
    ])
    mapUsers = jsonencode([])
  }
}

# Variable to accept multiple user definitions
variable "user_definitions" {
  description = "List of AWS IAM users with their corresponding roles and groups"
  type = list(object({
    user_name = string
    groups    = list(string)
  }))
  default = [
    # {
    #   user_name = "YOUR_ROLE_NAME_1"
    #   groups    = ["system:masters"]
    # },
    # {
    #   user_name = "YOUR_ROLE_NAME_2"
    #   groups    = ["system:masters"]
    # }
  ]
}