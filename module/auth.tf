locals {
  enabled = true  # Toggle this as needed to enable or disable resources

  # Example access entry map, replace with actual values as needed
  access_entry_map = {
    # "arn:aws:iam::123456789012:user/user1" = {
    #   kubernetes_groups = ["group1", "group2"]
    #   type              = "STANDARD"
    # },
    # "arn:aws:iam::123456789012:user/user2" = {
    #   kubernetes_groups = ["group3"]
    #   type              = "STANDARD"
    # }
  }

  # Example access policy association map, replace with actual values as needed
  eks_access_policy_association_product_map = {
    # "arn:aws:iam::123456789012:user/user1" = {
    #   principal_arn = "arn:aws:iam::123456789012:user/user1"
    #   policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    #   access_scope  = {
    #     type       = "ReadOnly"
    #     namespaces = ["default"]
    #   }
    # }
  }

  # Policy abbreviation map for dynamic policy ARN selection
  eks_policy_abbreviation_map = {
    "AmazonEKSClusterPolicy" = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }

  # Define the EKS cluster ID, you can also use `aws_eks_cluster.example.id` if the cluster is created in this configuration
  eks_cluster_id = aws_eks_cluster.example.id
}

#### auth.tf ## 

resource "aws_eks_access_entry" "map" {
  for_each = local.enabled ? local.access_entry_map : {}

  cluster_name      = local.eks_cluster_id
  principal_arn     = each.key
  kubernetes_groups = each.value.kubernetes_groups
  type              = each.value.type

  tags = aws_eks_cluster.example.tags
}

resource "aws_eks_access_policy_association" "map" {
  for_each = local.enabled ? local.eks_access_policy_association_product_map : {}

  cluster_name  = local.eks_cluster_id
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = local.access_entry_map[each.value.principal_arn].access_policy_associations[each.value.policy_arn].access_scope.type
    namespaces = local.access_entry_map[each.value.principal_arn].access_policy_associations[each.value.policy_arn].access_scope.namespaces
  }
}

resource "aws_eks_access_entry" "standard" {
  count = local.enabled ? length(var.access_entries) : 0

  cluster_name      = local.eks_cluster_id
  principal_arn     = var.access_entries[count.index].principal_arn
  kubernetes_groups = var.access_entries[count.index].kubernetes_groups
  type              = "STANDARD"

  tags = aws_eks_cluster.example.tags
}

resource "aws_eks_access_entry" "linux" {
  count = local.enabled ? length(lookup(var.access_entries_for_nodes, "EC2_LINUX", [])) : 0

  cluster_name  = local.eks_cluster_id
  principal_arn = var.access_entries_for_nodes["EC2_LINUX"][count.index]
  type          = "EC2_LINUX"

  tags = aws_eks_cluster.example.tags
}

resource "aws_eks_access_entry" "windows" {
  count = local.enabled ? length(lookup(var.access_entries_for_nodes, "EC2_WINDOWS", [])) : 0

  cluster_name  = local.eks_cluster_id
  principal_arn = var.access_entries_for_nodes["EC2_WINDOWS"][count.index]
  type          = "EC2_WINDOWS"

  tags = aws_eks_cluster.example.tags
}

resource "aws_eks_access_policy_association" "list" {
  count = local.enabled ? length(var.access_policy_associations) : 0

  cluster_name  = local.eks_cluster_id
  principal_arn = var.access_policy_associations[count.index].principal_arn
  policy_arn = try(local.eks_policy_abbreviation_map[var.access_policy_associations[count.index].policy_arn], var.access_policy_associations[count.index].policy_arn)

  access_scope {
    type       = var.access_policy_associations[count.index].access_scope.type
    namespaces = var.access_policy_associations[count.index].access_scope.namespaces
  }
}




#### Variables.tf  ####


variable "access_entries" {
  description = "List of access entries to be created in EKS"
  type = list(object({
    principal_arn     = string
    kubernetes_groups = list(string)
  }))
  default = [
    {
      principal_arn     = "arn:aws:iam::123456789012:user/user1"
      kubernetes_groups = ["group1", "group2"]
    }
  ]
}

variable "access_entries_for_nodes" {
  description = "Access entries for EC2 instances"
  type = map(list(string))
  default = {
    EC2_LINUX  = ["arn:aws:iam::123456789012:instance-profile/EC2LinuxRole"]
    EC2_WINDOWS = ["arn:aws:iam::123456789012:instance-profile/EC2WindowsRole"]
  }
}

variable "access_policy_associations" {
  description = "List of access policy associations to be linked to the EKS cluster"
  type = list(object({
    principal_arn = string
    policy_arn    = string
    access_scope  = object({
      type       = string
      namespaces = list(string)
    })
  }))
  default = [
    {
      principal_arn = "arn:aws:iam::123456789012:user/user1"
      policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      access_scope  = {
        type       = "ReadOnly"
        namespaces = ["default"]
      }
    }
  ]
}
