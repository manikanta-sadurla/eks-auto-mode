# Variables with Descriptions
variable "cluster_name" {
  description = "Name of the EKS cluster. Must meet naming constraints."
  type        = string
}


## VPC Config Variable ## 
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

## Log Type Variable ##
variable "enabled_cluster_log_types" {
  description = "Control plane logs to enable."
  type        = list(string)
  default     = []
}

variable "encryption_key_arn" {
  description = "KMS key ARN for encryption."
  type        = string
}

# variable "service_ipv4_cidr" {
#   description = "CIDR block for Kubernetes service IPs."
#   type        = string
# }

# variable "ip_family" {
#   description = "IP family for Kubernetes service addresses."
#   type        = string
#   default     = "ipv4"
# }

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

# variable "zonal_shift_enabled" {
#   description = "Enable zonal shift for the cluster."
#   type        = bool
#   default     = false
# }

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

### kubernetes_network_config Variables ###
variable "kubernetes_network_config_enabled" {
  description = "Whether to enable Kubernetes network configuration block."
  type        = bool
  default     = true
}

variable "elastic_load_balancing_enabled" {
  description = "Enable or disable Elastic Load Balancing for the cluster."
  type        = bool
  default     = true
}

variable "service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes pod and service IP addresses from."
  type        = string
  default     = ""
}

variable "ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses."
  type        = string
  default     = "ipv4"
}
##### Compute config variables ###
variable "compute_config_enabled" {
  description = "Whether to enable the compute configuration block."
  type        = bool
  default     = true
}

variable "compute_enabled" {
  description = "Enable or disable the compute capability for the EKS Auto Mode cluster."
  type        = bool
  default     = false
}

variable "node_pools" {
  description = "List of node pools for the compute configuration. Valid options are general-purpose and system."
  type        = list(string)
  default     = ["general-purpose", "system"]
}

### Remote Network Variables ###

variable "remote_network_config_enabled" {
  description = "Whether to enable the remote network configuration block."
  type        = bool
  default     = false
}

variable "remote_node_networks_cidrs" {
  description = "List of CIDRs for remote node networks that can contain hybrid nodes."
  type        = list(string)
  default     = []
}

variable "remote_pod_networks_cidrs" {
  description = "List of CIDRs for remote pod networks that can contain pods running Kubernetes webhooks on hybrid nodes."
  type        = list(string)
  default     = []
}

##### Zonal Shift Variables ##

variable "zonal_shift_enabled" {
  description = "Whether zonal shift is enabled for the cluster."
  type        = bool
  default     = false
}
