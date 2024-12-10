locals {
  enabled = true # Set to false if you don't want to create these resources
}
data "tls_certificate" "cluster" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = one(aws_eks_cluster.example[*].identity[0].oidc[0].issuer)
}

resource "aws_iam_openid_connect_provider" "default" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = one(aws_eks_cluster.example[*].identity[0].oidc[0].issuer)
  tags = {
    Environment = "poc"
    Project     = "play-hq"
  }

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [one(data.tls_certificate.cluster[*].certificates[0].sha1_fingerprint)]
}
variable "oidc_provider_enabled" {
  type    = bool
  default = true # Set to false if you don't want to create the OIDC provider
}

variable "addons_depends_on" {
  type    = list(any)
  default = []
}


############################################################################
### EKS ADD-ONS ############################################################
############################################################################

resource "aws_eks_addon" "addons" {
  for_each = var.eks_auto_mode ? { for addon in var.default_addons : addon.addon_name => addon } : { for addon in var.custom_addons : addon.addon_name => addon }

  cluster_name = aws_eks_cluster.example.name
  addon_name   = each.value.addon_name

  # Optional fields for custom add-ons
  addon_version               = lookup(each.value, "addon_version", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)
  depends_on = [ aws_eks_cluster.example ]
}

variable "custom_addons" {
  description = "List of custom add-ons to create if eks_auto_mode is false"
  type = list(object({
    addon_name                  = string
    addon_version               = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "PRESERVE")
    service_account_role_arn    = optional(string)
  }))
  default =  [
    {
      addon_name                  = "vpc-cni"
      addon_version               = "v1.19.0-eksbuild.1"
      # configuration_values        = jsonencode({
      #   replicaCount = 2
      # })
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    },
    {
      addon_name                  = "kube-proxy"
      addon_version               = "v1.31.2-eksbuild.3"
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    },
  ]
}

variable "default_addons" {
  description = "Default add-ons to create when eks_auto_mode is true"
  type = list(object({
    addon_name = string
  }))
  default = [
    { addon_name = "vpc-cni" },
    { addon_name = "kube-proxy" },
    { addon_name = "coredns" }
  ]
}

