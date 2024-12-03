# Required Variables
cluster_name          = "playhq-cluster"
kubernetes_version    = "1.31" 
# vpc_id                = "vpc-12345678"
subnet_ids            = ["subnet-12345678", "subnet-23456789"]
security_group_ids    = ["sg-12345678", "sg-23456789"]

authentication_mode              = "API_AND_CONFIG_MAP"
bootstrap_permissions            = false


bootstrap_self_managed_addons = true
enabled_cluster_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
encryption_key_arn = ""

#kubernetes_network_config 
  service_ipv4_cidr = "172.20.0.0/16"
  ip_family         = "ipv4"


#outpost_config 
  control_plane_instance_type = "m5.large"
  control_plane_placement_group = "my-placement-group"

  outpost_arns = []

#upgrade_policy 
  upgrade_support_type = "STANDARD"


# zonal_shift_config = {
#   enabled = false
# }

# Optional VPC Config
#vpc_config 
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["10.0.0.0/24"]


 # Kubernetes version (Optional, specify if required)
