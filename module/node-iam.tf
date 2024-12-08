# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_group_role" {
  name = var.node_group_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.node_group_tags
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "node_group_managed_policy_attachments" {
  for_each   = toset(var.node_group_managed_policies)
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = each.value
}

# Create Custom Policy for Node Group
resource "aws_iam_policy" "node_group_custom_policy" {
  name = var.node_group_custom_policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.node_group_custom_policy_statements : {
        Action   = statement.actions
        Effect   = statement.effect
        Resource = statement.resource
      }
    ]
  })
}

# Attach Custom Policy to the Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_custom_policy_attachment" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.node_group_custom_policy.arn
}


# Variables
variable "node_group_role_name" {
  description = "The name of the IAM role for EKS Node Group"
  default     = "eks-node-group-role"
}

variable "node_group_tags" {
  description = "Tags to apply to the Node Group IAM role"
  type        = map(string)
  default = {
    Environment = "dev"
    Name        = "eks-node-group-role"
  }
}

variable "node_group_managed_policies" {
  description = "List of AWS Managed Policies to attach to the Node Group IAM role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  ]
}

variable "node_group_custom_policy_name" {
  description = "Name of the custom IAM policy for Node Group"
  default     = "arc-poc-CNI_Policy"
}

variable "node_group_custom_policy_statements" {
  description = "Custom policy statements for Node Group"
  type = list(object({
    actions  = list(string)
    effect   = string
    resource = string
  }))
  default = [
    {
      actions = [
        "ec2:UnassignPrivateIpAddresses",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:DetachNetworkInterface",
        "ec2:DescribeTags",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DeleteNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:AssignIpv6Addresses"
      ]
      effect   = "Allow"
      resource = "*"
    },
    {
      actions  = ["ec2:CreateTags"]
      effect   = "Allow"
      resource = "arn:aws:ec2:*:*:network-interface/*"
    }
  ]
}