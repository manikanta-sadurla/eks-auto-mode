resource "aws_iam_role" "eks_cluster_role" {
  name = "EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# Attach AWS Managed Policies for EKS Cluster Role
# resource "aws_iam_role_policy_attachment" "eks_block_storage_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_networking_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

resource "aws_iam_role_policy_attachment" "eks_policies" {
  for_each = {
    "eks_block_storage" = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    # "eks_compute"       = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "eks_load_balancing"               = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "eks_networking"                   = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
    "eks_worker_node"                  = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "eks_container_registry_readyonly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "eks_cni_policy"                   = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    "eks_cluster"                      = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    "eks_service"                      = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"


  }

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster_role.name
}
# Output the ARN of the created IAM Role
output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}
