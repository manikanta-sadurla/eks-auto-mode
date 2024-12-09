resource "aws_eks_cluster" "example" {
  # Required Arguments
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    # security_group_ids      = var.security_group_ids
    security_group_ids = [aws_security_group.cluster.id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }
  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_permissions
  }

  upgrade_policy {
    support_type = var.upgrade_support_type
  }

  ### EKS Auto Mode ###

  ### When using EKS Auto Mode compute_config.enabled, kubernetes_network_config.elastic_load_balancing.enabled, 
  ## and storage_config.block_storage.enabled must *ALL be set to true. 
  #Likewise for disabling EKS Auto Mode, all three arguments must be set to false.

  bootstrap_self_managed_addons = false # When EKS Auto Mode is enabled, bootstrapSelfManagedAddons must be set to false

  # compute_config {
  #   enabled       = true
  #   node_pools    = ["general-purpose", "system"]
  #   node_role_arn = aws_iam_role.eks_node_group_role.arn
  # }

# Conditional Compute Config
dynamic "compute_config" {
  for_each = var.compute_config_enabled ? [1] : []
  content {
    # Enable or Disable Compute Capability
    enabled = var.compute_enabled

    # Node Pools Configuration
    node_pools = var.node_pools != [] ? var.node_pools : ["general-purpose", "system"]

    # Node Role ARN
    node_role_arn = aws_iam_role.eks_node_group_role.arn
  }
}

  # kubernetes_network_config {
  #   elastic_load_balancing {
  #     enabled = true
  #   }
  # }

  # Conditional Kubernetes Network Config
dynamic "kubernetes_network_config" {
  for_each = var.kubernetes_network_config_enabled ? [1] : []
  content {
    # Elastic Load Balancing Configuration
    elastic_load_balancing {
      enabled = var.elastic_load_balancing_enabled
    }

    # Service IPv4 CIDR
    service_ipv4_cidr = var.service_ipv4_cidr != "" ? var.service_ipv4_cidr : null

    # IP Family
    ip_family = var.ip_family != "" ? var.ip_family : "ipv4"
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


# Conditional Remote Network Config
dynamic "remote_network_config" {
  for_each = var.remote_network_config_enabled ? [1] : []
  content {
    # Remote Node Networks Configuration
    dynamic "remote_node_networks" {
      for_each = length(var.remote_node_networks_cidrs) > 0 ? [1] : []
      content {
        cidrs = var.remote_node_networks_cidrs
      }
    }

    # Remote Pod Networks Configuration
    dynamic "remote_pod_networks" {
      for_each = length(var.remote_pod_networks_cidrs) > 0 ? [1] : []
      content {
        cidrs = var.remote_pod_networks_cidrs
      }
    }
  }
}

## Zonal shift config ##

zonal_shift_config {
  enabled = var.zonal_shift_enabled
}



  tags = merge(var.default_tags, var.resource_tags)
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the cluster will be created"
}

resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster"
    }
  )
}
