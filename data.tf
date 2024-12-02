######################################################################
## data lookup
######################################################################
# data "aws_eks_cluster" "cluster" {
#   name = module.eks_cluster.eks_cluster_id
#   depends_on = [ module.eks_cluster ]
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks_cluster.eks_cluster_id
#   depends_on = [ module.eks_cluster ]
# }

# fetching codebuild role arn
# data "aws_ssm_parameter" "codebuild_role" {
#   name = "/${var.namespace}/${var.environment}/codebuild_role"
# }

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.namespace}-${var.environment}-vpc"]
  }
}

## network
data "aws_subnets" "public" {
  filter {
    name = "tag:Name"
    values = [
      "${var.namespace}-${var.environment}-public-subnet-public-${var.region}a",
      "${var.namespace}-${var.environment}-public-subnet-public-${var.region}b"
    ]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "tag:Name"
    values = [
      "${var.namespace}-${var.environment}-private-subnet-private-${var.region}a",
      "${var.namespace}-${var.environment}-private-subnet-private-${var.region}b"
    ]
  }
}

## security
data "aws_security_groups" "db_sg" {
  filter {
    name   = "eks-automode"
    values = ["${var.namespace}-${var.environment}-db-sg"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_security_groups" "eks_sg" {
  filter {
    name   = "eks-automode"
    values = ["${var.namespace}-${var.environment}-eks-sg"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_eks_cluster" "eks" {
  name = module.eks_cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks_cluster.eks_cluster_id
}