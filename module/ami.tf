# locals {
#   given_ami_id = length(var.ami_image_id) > 0
#   need_to_get_ami_id = length(var.ami_image_id) == 0

#   # Public SSM parameters all start with /aws/service/
#   ami_os = split("_", var.ami_type)[0]

#   # Format string that makes the SSM parameter name to retrieve
#   ami_ssm_format = {
#     AL2_x86_64                 = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2/%[1]v/image_id"
#     AL2_x86_64_GPU             = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2-gpu/%[1]v/image_id"
#     AL2_ARM_64                 = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2-arm64/%[1]v/image_id"
#     AL2023_x86_64_STANDARD     = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2023/x86_64/standard/%[1]v/image_id"
#     AL2023_ARM_64_STANDARD     = "/aws/service/eks/optimized-ami/%[2]v/amazon-linux-2023/arm64/standard/%[1]v/image_id"
#     BOTTLEROCKET_x86_64        = "/aws/service/bottlerocket/aws-k8s-%[2]v/x86_64/%[1]v/image_id"
#     BOTTLEROCKET_ARM_64        = "/aws/service/bottlerocket/aws-k8s-%[2]v/arm64/%[1]v/image_id"
#     BOTTLEROCKET_x86_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-%[2]v-nvidia/x86_64/%[1]v/image_id"
#     BOTTLEROCKET_ARM_64_NVIDIA = "/aws/service/bottlerocket/aws-k8s-%[2]v-nvidia/arm64/%[1]v/image_id"
#     WINDOWS_CORE_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Core-EKS_Optimized-%[2]v/image_id"
#     WINDOWS_FULL_2019_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-EKS_Optimized-%[2]v/image_id"
#     WINDOWS_CORE_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Core-EKS_Optimized-%[2]v/image_id"
#     WINDOWS_FULL_2022_x86_64   = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-EKS_Optimized-%[2]v/image_id"
#   }

#   release_version_parts              = concat(split("-", try(var.ami_release_version[0], "")), ["", ""])
#   amazon_linux_ami_name_release_part = try(join(".", slice(split(".", local.release_version_parts[0]), 0, 2)), "")

#   ami_specifier_amazon_linux = {
#     AL2_x86_64             = format("amazon-eks-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
#     AL2_x86_64_GPU         = format("amazon-eks-gpu-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
#     AL2_ARM_64             = format("amazon-eks-arm64-node-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
#     AL2023_x86_64_STANDARD = format("amazon-eks-node-al2023-x86_64-standard-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
#     AL2023_ARM_64_STANDARD = format("amazon-eks-node-al2023-arm64-standard-%v-v%v", local.amazon_linux_ami_name_release_part, local.release_version_parts[1])
#   }

#   ami_specifier = length(var.ami_release_version) == 0 ? (local.ami_os == "BOTTLEROCKET" ? "latest" : "recommended") : (
#     lookup(local.ami_specifier_amazon_linux, var.ami_type, var.ami_release_version[0])
#   )

#   # Handle Windows-specific AMI names
#   is_window_version = local.ami_os == "WINDOWS" && local.ami_specifier != "recommended"
#   windows_name_base = {
#     WINDOWS_CORE_2019_x86_64 = "Windows_Server-2019-English-Core-EKS_Optimized"
#     WINDOWS_FULL_2019_x86_64 = "Windows_Server-2019-English-Full-EKS_Optimized"
#     WINDOWS_CORE_2022_x86_64 = "Windows_Server-2022-English-Core-EKS_Optimized"
#     WINDOWS_FULL_2022_x86_64 = "Windows_Server-2022-English-Full-EKS_Optimized"
#   }

#   ami_name_windows = { for k, v in local.windows_name_base : k => format("%s-%s", v, try(var.ami_release_version[0], "")) }

#   # Fetch the AMI ID either from custom input or dynamically from SSM or AWS AMI
#   fetched_ami_id = try(local.is_window_version ? data.aws_ami.windows_ami[0].image_id : data.aws_ssm_parameter.ami_id[0].insecure_value, "")
#   ami_id         = local.given_ami_id ? var.ami_image_id[0] : local.fetched_ami_id
# }

# # Fetch the AMI ID from SSM Parameter Store if needed
# data "aws_ssm_parameter" "ami_id" {
#   count = local.need_to_get_ami_id && !local.is_window_version ? 1 : 0

#   name = format(local.ami_ssm_format[var.ami_type], local.ami_specifier, var.kubernetes_version)

#   lifecycle {
#     precondition {
#       condition     = var.ami_type != "CUSTOM"
#       error_message = "The AMI ID must be supplied when AMI type is \"CUSTOM\"."
#     }
#   }
# }

# # Fetch the Windows AMI if it's a Windows-based OS
# data "aws_ami" "windows_ami" {
#   count = local.need_to_get_ami_id && local.is_window_version ? 1 : 0

#   owners = ["amazon"]
#   filter {
#     name   = "name"
#     values = [local.ami_name_windows[var.ami_type]]
#   }
# }



# variable "ami_type" {
#   type        = string
#   description = <<-EOT
#     Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
#     Defaults to `AL2_x86_64`. Valid values: `AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64_NVIDIA, BOTTLEROCKET_x86_64_NVIDIA, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64, WINDOWS_CORE_2022_x86_64, WINDOWS_FULL_2022_x86_64, AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD`.
#     EOT
#   default     = "AL2_x86_64"
#   nullable    = false
#   validation {
#     condition = (
#       contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64", "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD"], var.ami_type)
#     )
#     error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", \"AL2023_x86_64_STANDARD\", \"AL2023_ARM_64_STANDARD\", or \"CUSTOM\"."
#   }
# }

# variable "ami_image_id" {
#   type        = list(string)
#   description = "AMI to use, overriding other AMI specifications, but must match `ami_type`. Ignored if `launch_template_id` is supplied."
#   default     = []
#   nullable    = false
#   validation {
#     condition = (
#       length(var.ami_image_id) < 2
#     )
#     error_message = "You may not specify more than one `ami_image_id`."
#   }
# }

# variable "ami_release_version" {
#   type        = list(string)
#   description = <<-EOT
#     The EKS AMI "release version" to use. Defaults to the latest recommended version.
#     For Amazon Linux, it is the "Release version" from [Amazon AMI Releases](https://github.com/awslabs/amazon-eks-ami/releases)
#     For Bottlerocket, it is the release tag from [Bottlerocket Releases](https://github.com/bottlerocket-os/bottlerocket/releases) without the "v" prefix.
#     For Windows, it is "AMI version" from [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html).
#     Note that unlike AMI names, release versions never include the "v" prefix.
#     Examples:
#       AL2: 1.29.3-20240531
#       Bottlerocket: 1.2.0 or 1.2.0-ccf1b754
#       Windows: 1.29-2024.04.09
#     EOT
#   # Normally we would not validate this input and instead allow the AWS API to validate it,
#   # but in this case, our AMI selection logic depends on it being in a format we expect,
#   # so even if AWS adds options in the future, we need to ensure it is in a format we can handle.
#   validation {
#     condition = (
#       length(var.ami_release_version) == 0 ? true : length(
#         # 1.2.3 with optional -20240531 or -7452c37e   or 1.2.3               or 1.2-2024.04.09
#       regexall("(^\\d+\\.\\d+\\.\\d+(-[\\da-f]{8})?$)|(^\\d+\\.\\d+\\.\\d+$)|(^\\d+\\.\\d+-\\d+\\.\\d+\\.\\d+$)", var.ami_release_version[0])) == 1
#     )
#     error_message = <<-EOT
#         Var ami_release_version, if supplied, must be like
#           Amazon Linux 2 or 2023: 1.29.3-20240531
#           Bottlerocket: 1.18.0 or 1.18.0-7452c37e # note commit hash prefix is 8 characters, not GitHub's default 7
#           Windows: 1.29-2024.04.09
#         EOT
#   }
#   default  = []
#   nullable = false
# }