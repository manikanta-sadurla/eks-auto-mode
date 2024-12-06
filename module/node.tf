# IAM role for the EKS node group
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required IAM policies to the role
resource "aws_iam_role_policy_attachment" "eks_node_group_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# resource "aws_iam_role_policy_attachment" "ssm_path" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "ssm_managed" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_node_group_registry_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node_group_role.name
# }




# Launch Template for EKS Node Group
# resource "aws_launch_template" "eks_node_launch_template" {
#   name_prefix = "eks-node-launch-template"

#   ebs_optimized = true

#   dynamic "block_device_mappings" {
#     for_each = var.launch_template_block_device_mappings
#     content {
#       device_name  = block_device_mappings.key
#       no_device    = block_device_mappings.value.no_device
#       virtual_name = block_device_mappings.value.virtual_name

#       dynamic "ebs" {
#         for_each = block_device_mappings.value.ebs == null ? [] : [block_device_mappings.value.ebs]
#         content {
#           delete_on_termination = ebs.value.delete_on_termination
#           encrypted             = ebs.value.encrypted
#           iops                  = ebs.value.iops
#           kms_key_id            = ebs.value.kms_key_id
#           snapshot_id           = ebs.value.snapshot_id
#           throughput            = ebs.value.throughput
#           volume_size           = ebs.value.volume_size
#           volume_type           = ebs.value.volume_type
#         }
#       }
#     }
#   }

#   # image_id = var.image_id
#   # image_id = local.ami_id

#   # image_id = data.aws_ami.amazon_linux.id
#   image_id = data.aws_ssm_parameter.eks_ami_release_version.value
#   key_name = var.key_name

#   dynamic "tag_specifications" {
#     for_each = var.launch_template_tag_specifications
#     content {
#       resource_type = tag_specifications.value
#       #   tags          = var.node_tags
#     }
#   }
# }

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  ami_type        = "AL2_x86_64"
  # ami_type       = "CUSTOM"
  instance_types = ["t3.medium"]
  # release_version = data.aws_ssm_parameter.eks_ami_release_version.value
  # release_version = local.ami_id == "" ? data.aws_ssm_parameter.eks_ami_release_version.value : null
  release_version = null

  ### you cannot specify both the launch_template block and the remote_access block simultaneously

  # launch_template {
  #   id      = aws_launch_template.eks_node_launch_template.id
  #   version = "$Latest"
  # }

  #   remote_access {
  #     ec2_ssh_key = var.ec2_ssh_key
  #     source_security_group_ids = var.source_security_group_ids
  #   }

  tags = {
    "Environment" = "Production"
    "Team"        = "DevOps"
  }

  depends_on = [ aws_iam_role_policy_attachment.eks_node_group_cni_policy,
                 aws_iam_role_policy_attachment.eks_node_group_worker_policy,
                 aws_iam_role_policy_attachment.eks_node_group_registry_policy,
                 aws_iam_role_policy_attachment.eks_node_group_registry_policy,
                #  aws_iam_role_policy_attachment.ssm_path,
                #  aws_iam_role_policy_attachment.ssm_managed,
                 ]
}

# Example Subnets for EKS Node Group
# resource "aws_subnet" "example" {
#   count = 2

#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
#   vpc_id            = aws_vpc.example.id
# }

# Data to get the EKS optimized AMI version
data "aws_ssm_parameter" "eks_ami_release_version" {
  # name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.example.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
  # name = "/aws/service/eks/optimized-ami/1.30/amazon-linux-2023/x86_64/nvidia/amazon-eks-node-al2023-x86_64-nvidia-560-1.31-v20241016/image_id"
  name = "/aws/service/eks/optimized-ami/1.30/amazon-linux-2023/x86_64/nvidia/amazon-eks-node-al2023-x86_64-nvidia-1.30-v20241024/image_id"
}

# EKS Cluster Example (Use your actual cluster name and configuration)
# resource "aws_eks_cluster" "example" {
#   name     = "example-cluster"
#   role_arn = aws_iam_role.eks_node_group_role.arn
#   version  = "1.23"

#   vpc_config {
#     subnet_ids = aws_subnet.example[*].id
#   }
# }


variable "launch_template_block_device_mappings" {
  description = "Block device mappings for the launch template."
  type = list(object({
    device_name           = string
    ebs_optimized         = optional(bool)
    delete_on_termination = optional(bool, true)
    volume_size           = optional(number)
    volume_type           = optional(string, "gp2")
  }))
  default = []
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


# variable "image_id" {
#   description = "AMI ID to use for the EC2 instance."
#   type        = string

# }

variable "key_name" {
  description = "The name of the SSH key pair to use for the EC2 instance."
  type        = string
  default     = ""
}

variable "launch_template_tag_specifications" {
  description = "Tag specifications for the launch template."
  type = list(object({
    resource_type = string
    tags          = map(string)
  }))
  default = []
}
