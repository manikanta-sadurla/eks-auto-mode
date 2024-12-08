# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "managed_policy_attachments" {
  for_each = toset(var.aws_managed_policies)
  role     = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}

# Create Custom Policy
resource "aws_iam_policy" "custom_policy" {
  name   = var.custom_policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.custom_policy_statements : {
        Sid      = statement.sid
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resource
      }
    ]
  })
}

# Attach Custom Policy
resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}


# Variables
variable "role_name" {
  description = "The name of the IAM role for EKS Cluster"
  default     = "eks-cluster-role-manikanta"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    Name        = "eks-cluster-role-manikanta"
  }
}

variable "aws_managed_policies" {
  description = "List of AWS Managed Policies to attach to the IAM role"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]
}

variable "custom_policy_name" {
  description = "Name of the custom IAM policy"
  default     = "arc-poc-cluster-ServiceRole-manikanta"
}

variable "custom_policy_statements" {
  description = "Custom policy statements"
  type = list(object({
    sid      = string
    effect   = string
    actions  = list(string)
    resource = string
  }))
  default = [
    {
      sid      = "AllowElasticLoadBalancer"
      effect   = "Allow"
      actions  = [
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetIpAddressType",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeAddresses",
        "ec2:DescribeAccountAttributes"
      ]
      resource = "*"
    },
    {
      sid      = "DenyCreateLogGroup"
      effect   = "Deny"
      actions  = ["logs:CreateLogGroup"]
      resource = "*"
    }
  ]
}