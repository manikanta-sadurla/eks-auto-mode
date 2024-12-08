
data "aws_partition" "current" {}

locals {
    create = true

partition = data.aws_partition.current.partition
  # This replaces the one-time logic from the EKS API with something that can be
  # better controlled by users through Terraform
  bootstrap_cluster_creator_admin_permissions = {
    cluster_creator = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Merge the bootstrap behavior with the entries that users provide
  merged_access_entries = merge(
    { for k, v in local.bootstrap_cluster_creator_admin_permissions : k => v if var.enable_cluster_creator_admin_permissions },
    var.access_entries,
  )

  # Flatten out entries and policy associations so users can specify the policy
  # associations within a single entry
  flattened_access_entries = flatten([
    for entry_key, entry_val in local.merged_access_entries : [
      for pol_key, pol_val in lookup(entry_val, "policy_associations", {}) :
      merge(
        {
          principal_arn = entry_val.principal_arn
          entry_key     = entry_key
          pol_key       = pol_key
        },
        { for k, v in {
          association_policy_arn              = pol_val.policy_arn
          association_access_scope_type       = pol_val.access_scope.type
          association_access_scope_namespaces = lookup(pol_val.access_scope, "namespaces", [])
        } : k => v if !contains(["EC2", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX", "HYBRID_LINUX"], lookup(entry_val, "type", "STANDARD")) },
      )
    ]
  ])
}



resource "aws_ec2_tag" "cluster_primary_security_group" {
  for_each = { for k, v in merge(var.tags) :
    k => v if local.create && k != "Name" && var.create_cluster_primary_security_group_tags
  }

  resource_id = aws_eks_cluster.example.id  # Use the EKS cluster ID instead of security group ID
  key         = each.key
  value       = each.value
}


resource "aws_cloudwatch_log_group" "this" {
  count = local.create && var.create_cloudwatch_log_group ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(
    var.tags,
    # var.cloudwatch_log_group_tags,
    { Name = "/aws/eks/${var.cluster_name}/cluster" }
  )
}


resource "aws_eks_access_entry" "this" {
  for_each = { for k, v in local.merged_access_entries : k => v if local.create }

  cluster_name      = aws_eks_cluster.example.id
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  user_name         = try(each.value.user_name, null)

  tags = merge(var.tags, try(each.value.tags, {}))
}


resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in local.flattened_access_entries : "${v.entry_key}_${v.pol_key}" => v if local.create }

  access_scope {
    namespaces = try(each.value.association_access_scope_namespaces, [])
    type       = each.value.association_access_scope_type
  }

  cluster_name = aws_eks_cluster.example.id

  policy_arn    = each.value.association_policy_arn
  principal_arn = each.value.principal_arn

  depends_on = [
    aws_eks_access_entry.this,
  ]
}


####################################################


# variable "cluster_name" {
#   description = "The name of the EKS Cluster"
#   type        = string
# }

# variable "role_name" {
#   description = "The name of the IAM role for EKS Cluster"
#   default     = "eks-cluster-role-manikanta"
# }

# variable "tags" {
#   description = "Tags to apply to resources"
#   type        = map(string)
#   default = {
#     Environment = "dev"
#     Name        = "eks-cluster-role-manikanta"
#   }
# }

# variable "aws_managed_policies" {
#   description = "List of AWS Managed Policies to attach to the IAM role"
#   type        = list(string)
#   default = [
#     "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
#     "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   ]
# }

# variable "custom_policy_name" {
#   description = "Name of the custom IAM policy"
#   default     = "arc-poc-cluster-ServiceRole-manikanta"
# }

# variable "custom_policy_statements" {
#   description = "Custom policy statements"
#   type = list(object({
#     sid      = string
#     effect   = string
#     actions  = list(string)
#     resource = string
#   }))
#   default = [
#     {
#       sid    = "AllowElasticLoadBalancer"
#       effect = "Allow"
#       actions = [
#         "elasticloadbalancing:SetSubnets",
#         "elasticloadbalancing:SetIpAddressType",
#         "ec2:DescribeInternetGateways",
#         "ec2:DescribeAddresses",
#         "ec2:DescribeAccountAttributes"
#       ]
#       resource = "*"
#     },
#     {
#       sid      = "DenyCreateLogGroup"
#       effect   = "Deny"
#       actions  = ["logs:CreateLogGroup"]
#       resource = "*"
#     }
#   ]
# }

variable "enable_cluster_creator_admin_permissions" {
  description = "Flag to enable cluster creator admin permissions"
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Custom access entries for the EKS cluster"
  type = list(object({
    principal_arn     = string
    type              = string
    kubernetes_groups = list(string)
    user_name         = string
    tags              = map(string)
  }))
  default = []
}

variable "create_cluster_primary_security_group_tags" {
  description = "Flag to create tags for the primary security group"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Flag to create CloudWatch log group"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention period for CloudWatch log group"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ID for CloudWatch log group"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_class" {
  description = "Log group class"
  type        = string
  default     = "STANDARD"
}

variable "create" {
  description = "Flag to enable resource creation"
  type        = bool
  default     = true
}

variable "partition" {
  description = "AWS partition (e.g., aws, aws-us-gov, aws-cn)"
  type        = string
  default     = "aws"
}
