# Fetch AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Create the Kubernetes ConfigMap dynamically
# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = jsonencode([
#       for user in var.user_definitions : {
#         rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.user_name}"
#         username = user.user_name
#         groups   = user.groups
#       }
#     ])
#     mapUsers = jsonencode([])
#   }
# }

# # Variable to accept multiple user definitions
# variable "user_definitions" {
#   description = "List of AWS IAM users with their corresponding roles and groups"
#   type = list(object({
#     user_name = string
#     groups    = list(string)
#   }))
#   default = [
#     # {
#     #   user_name = "YOUR_ROLE_NAME_1"
#     #   groups    = ["system:masters"]
#     # },
#     # {
#     #   user_name = "YOUR_ROLE_NAME_2"
#     #   groups    = ["system:masters"]
#     # }
#   ]
# }