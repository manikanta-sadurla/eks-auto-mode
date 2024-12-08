
data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

locals {
  create = true

  partition = data.aws_partition.current.partition

  bootstrap_cluster_creator_admin_permissions = {
    cluster_creator = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn     = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Convert access_entries list to a map
  access_entries_map = {
    for entry in var.access_entries : entry.principal_arn => entry
  }

  # Merge the bootstrap permissions and the converted access_entries map
  merged_access_entries = merge(
    local.bootstrap_cluster_creator_admin_permissions,
    local.access_entries_map
  )
  
  # Flatten the merged access entries with the condition
  flattened_access_entries = flatten([
    for entry_key, entry_val in local.merged_access_entries : [
      for pol_key, pol_val in lookup(entry_val, "policy_associations", {}) :
      merge(
        {
          principal_arn = entry_val.principal_arn
          entry_key     = entry_key
          pol_key       = pol_key
        },
        {
          association_policy_arn              = pol_val.policy_arn
          association_access_scope_type       = pol_val.access_scope.type
          association_access_scope_namespaces = lookup(pol_val.access_scope, "namespaces", [])
        },
        # Filtering out specific types as per your original condition
        { for k, v in pol_val : k => v if !contains(["EC2", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX", "HYBRID_LINUX"], lookup(entry_val, "type", "STANDARD")) }
      )
    ]
  ])
}





# resource "aws_ec2_tag" "cluster_primary_security_group" {
#   for_each = { for k, v in merge(var.tags) :
#     k => v if local.create && k != "Name" && var.create_cluster_primary_security_group_tags
#   }

#   resource_id = aws_eks_cluster.example.id  # Use the EKS cluster ID instead of security group ID
#   key         = each.key
#   value       = each.value
# }


# resource "aws_cloudwatch_log_group" "this" {
#   count = local.create && var.create_cloudwatch_log_group ? 1 : 0

#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = var.cloudwatch_log_group_retention_in_days
#   kms_key_id        = var.cloudwatch_log_group_kms_key_id
#   log_group_class   = var.cloudwatch_log_group_class

#   tags = merge(
#     var.tags,
#     # var.cloudwatch_log_group_tags,
#     { Name = "/aws/eks/${var.cluster_name}/cluster" }
#   )
# }


# resource "aws_eks_access_entry" "this" {
#   for_each = { for k, v in local.merged_access_entries : k => v if local.create }

#   cluster_name      = aws_eks_cluster.example.id
#   kubernetes_groups = try(each.value.kubernetes_groups, null)
#   principal_arn     = each.value.principal_arn
#   type              = try(each.value.type, "STANDARD")
#   user_name         = try(each.value.user_name, null)

#   tags = merge(var.tags, try(each.value.tags, {}))
# }


resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in local.flattened_access_entries : "${v.entry_key}_${v.pol_key}" => v if local.create }

  access_scope {
    namespaces = try(each.value.association_access_scope_namespaces, [])
    type       = each.value.association_access_scope_type
  }

  cluster_name = aws_eks_cluster.example.id

  policy_arn    = each.value.association_policy_arn
  principal_arn = each.value.principal_arn

#   depends_on = [
#     aws_eks_access_entry.this,
#   ]
}


####################################################


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
