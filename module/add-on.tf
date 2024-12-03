data "tls_certificate" "cluster" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = one(aws_eks_cluster.example[*].identity[0].oidc[0].issuer)
}

resource "aws_iam_openid_connect_provider" "default" {
  count = local.enabled && var.oidc_provider_enabled ? 1 : 0
  url   = one(aws_eks_cluster.example[*].identity[0].oidc[0].issuer)
  tags  = module.label.tags

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [one(data.tls_certificate.cluster[*].certificates[0].sha1_fingerprint)]
}

resource "aws_eks_addon" "cluster" {
  for_each = local.enabled ? {for addon in var.addons : addon.addon_name => addon} : {}

  cluster_name                = one(aws_eks_cluster.example[*].name)
  addon_name                  = each.key
  addon_version               = lookup(each.value, "addon_version", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", try(replace(each.value.resolve_conflicts, "PRESERVE", "NONE"), null))
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", lookup(each.value, "resolve_conflicts", null))
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  tags = module.label.tags

  depends_on = [

    aws_eks_cluster.example,
    aws_iam_openid_connect_provider.default, # Ensure the OIDC provider is created before add-ons
  ]

  timeouts {
    create = each.value.create_timeout
    update = each.value.update_timeout
    delete = each.value.delete_timeout
  }
}

locals {
  enabled = true  # Set to false if you don't want to create these resources
}

variable "oidc_provider_enabled" {
  type    = bool
  default = true  # Set to false if you don't want to create the OIDC provider
}

variable "addons_depends_on" {
  type    = list(any)
  default = []
}


variable "addons" {
  type = list(object({
    addon_name             = string
    addon_version          = string
    configuration_values   = map(string)
    resolve_conflicts      = string
    resolve_conflicts_on_create = string
    resolve_conflicts_on_update = string
    service_account_role_arn = string
    create_timeout         = string
    update_timeout         = string
    delete_timeout         = string
  }))
  default = [
    # {
    #   addon_name             = "vpc-cni"
    #   addon_version          = "v1.9.0-eksbuild.1"
    #   configuration_values   = {}
    #   resolve_conflicts      = "PRESERVE"
    #   resolve_conflicts_on_create = "NONE"
    #   resolve_conflicts_on_update = "NONE"
    #   service_account_role_arn = null
    #   create_timeout         = "30m"
    #   update_timeout         = "30m"
    #   delete_timeout         = "30m"
    # },
    # Add other add-ons as needed
  ]
}


