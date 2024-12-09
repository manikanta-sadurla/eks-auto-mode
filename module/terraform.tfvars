# Required Variables
cluster_name       = "playhq-cluster"
kubernetes_version = "1.31"

# vpc_id                = "vpc-12345678"
vpc_id                = "vpc-0e6c09980580ecbf6"
subnet_ids         = ["subnet-066d0c78479b72e77", "subnet-064b80a494fed9835"]
security_group_ids = ["sg-02969d9cf1e07897c"]

authentication_mode   = "API_AND_CONFIG_MAP"
bootstrap_permissions = true


# bootstrap_self_managed_addons = true
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
encryption_key_arn        = ""

#kubernetes_network_config 
service_ipv4_cidr = "172.20.0.0/16"
ip_family         = "ipv4"


#outpost_config 
control_plane_instance_type   = "m5.large"
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
# public_access_cidrs     = ["10.0.0.0/24"]
public_access_cidrs = ["0.0.0.0/0"]


user_definitions = [
  {
    user_name = "manikanta.sadurla"
    groups    = ["system:masters"]
  },
  # {
  #   user_name = "ReadOnlyRole"
  #   groups    = ["read-only"]
  # }
]



############# IAM #####################

role_name = "prod-eks-cluster-role-maniankta"

tags = {
  Environment = "prod"
  Name        = "prod-eks-cluster-role-maniaknta"
}

custom_policy_name = "arc-poc-cluster-ServiceRole-manikanta"

aws_managed_policies = [
  "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
  "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
  "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
  "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  
]

################ IAM NODE #######################

node_group_role_name = "prod-eks-node-group-role-manikanta"
node_group_tags = {
  Environment = "prod"
  Name        = "prod-eks-node-group-role-manikanta"
}

node_group_custom_policy_name = "arc-poc-CNI_Policy-manikanta"

node_group_managed_policies = [
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
]