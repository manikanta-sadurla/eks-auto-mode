# Launch Template for EKS Node Group
# Launch Template Configuration
resource "aws_launch_template" "eks_node_launch_template" {
  name_prefix   = "eks-node-group-"
  # version_description = "v1"
  # image_id      = var.ami_type == "AL2_x86_64" ? data.aws_ssm_parameter.eks_ami_release_version.value : var.custom_ami_id
# image_id      = var.ami_type == "AL2_x86_64" ? data.aws_ssm_parameter.eks_ami_release_version.value : data.aws_ssm_parameter.eks_ami_release_version.value
  # instance_type = join(",", var.instance_types)

  key_name = var.ec2_ssh_key != "" ? var.ec2_ssh_key : null

  security_group_names = length(var.source_security_group_ids) > 0 ? var.source_security_group_ids : null

  # user_data = base64encode(data.template_file.eks_userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    # tags = merge(var.tags, {
    #   "LaunchTemplate" = "true"
    # })
    tags = {
      "LaunchTemplate" = "true"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Define launch template variables
variable "instance_types" {
  description = "List of EC2 instance types for the EKS node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "custom_ami_id" {
  description = "Custom AMI ID for the EKS node group when ami_type is set to CUSTOM."
  type        = string
  default     = "" # You can leave it empty or set it to a specific AMI ID
}
variable "ami_type" {
  description = "AMI type for the EKS node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "ec2_ssh_key" {
  description = "EC2 SSH key name for remote access."
  type        = string
  default     = "" # Optional, leave empty if no SSH key is required
}

variable "source_security_group_ids" {
  description = "List of security group IDs for SSH access."
  type        = list(string)
  default     = [] # Optional, leave empty if not required
}

# variable "tags" {
#   description = "Tags to apply to the launch template."
#   type        = map(string)
#   default     = {
#     "Environment" = "Production"
#     "Team"        = "DevOps"
#   }
# }

# EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-node-group-playhq"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type = "AL2_x86_64" 
  # ami_type       = "CUSTOM" ## CUSTOM if launch template is configures 
  instance_types = ["t3.medium"]
  release_version = data.aws_ssm_parameter.eks_ami_release_version.value
  # release_version = local.ami_id == "" ? data.aws_ssm_parameter.eks_ami_release_version.value : null
  # release_version = null

  ### you cannot specify both the launch_template block and the remote_access block simultaneously

  launch_template {
    id      = aws_launch_template.eks_node_launch_template.id
    version = "$Latest"
  }

  #   remote_access {
  #     ec2_ssh_key = var.ec2_ssh_key
  #     source_security_group_ids = var.source_security_group_ids
  #   }

  tags = {
    "Environment" = "Production"
    "Team"        = "DevOps"
  }

  # depends_on = [ aws_iam_role_policy_attachment.eks_node_group_cni_policy,
  #                ]
}

# Data to get the EKS optimized AMI version
data "aws_ssm_parameter" "eks_ami_release_version" {
  # name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.example.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
  name = "/aws/service/eks/optimized-ami/1.30/amazon-linux-2-arm64/amazon-eks-arm64-node-1.30-v20240729/release_version"
  # name = "/aws/service/eks/optimized-ami/1.30/amazon-linux-2023/x86_64/nvidia/amazon-eks-node-al2023-x86_64-nvidia-560-1.31-v20241016/image_id"
  # name = "/aws/service/eks/optimized-ami/1.30/amazon-linux-2023/x86_64/nvidia/amazon-eks-node-al2023-x86_64-nvidia-1.30-v20241024/image_id"
}



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
#   # key_name = var.key_name

#   dynamic "tag_specifications" {
#     for_each = var.launch_template_tag_specifications
#     content {
#       resource_type = tag_specifications.value
#       #   tags          = var.node_tags
#     }
#   }
# }