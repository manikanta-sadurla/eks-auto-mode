# Variables with Descriptions
variable "cluster_name" {
  description = "Name of the EKS cluster. Must meet naming constraints."
  type        = string
}

# variable "role_arn" {
#   description = "IAM Role ARN for EKS control plane API access."
#   type        = string
# }

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cross-account elastic network interfaces."
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for communication with the Kubernetes control plane."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable or disable public API endpoint access."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable or disable private API endpoint access."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed for public API access."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control plane logs to enable."
  type        = list(string)
  default     = []
}

variable "encryption_key_arn" {
  description = "KMS key ARN for encryption."
  type        = string
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs."
  type        = string
}

variable "ip_family" {
  description = "IP family for Kubernetes service addresses."
  type        = string
  default     = "ipv4"
}

variable "authentication_mode" {
  description = "Authentication mode for the cluster."
  type        = string
  default     = "CONFIG_MAP"
}

variable "bootstrap_permissions" {
  description = "Whether to bootstrap cluster creator admin permissions."
  type        = bool
  default     = false
}

variable "upgrade_support_type" {
  description = "Support type for the cluster (STANDARD or EXTENDED)."
  type        = string
  default     = "STANDARD"
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for the EKS control plane."
  type        = string
}

variable "control_plane_placement_group" {
  description = "Placement group name for control plane instances."
  type        = string
}

variable "outpost_arns" {
  description = "ARNs of the Outposts for the EKS cluster."
  type        = list(string)
}

variable "zonal_shift_enabled" {
  description = "Enable zonal shift for the cluster."
  type        = bool
  default     = false
}

variable "bootstrap_self_managed_addons" {
  description = "Install default unmanaged add-ons during cluster creation."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster."
  type        = string
  default     = "1.25"
}

variable "default_tags" {
  description = "Default tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "resource_tags" {
  description = "Additional resource-specific tags."
  type        = map(string)
  default     = {}
}