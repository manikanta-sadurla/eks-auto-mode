# simple/terraform.tfvars
aws_region = "us-west-1"
name       = "myapp"
environment = "dev"

vpc_id     = "vpc-0e6c09980580ecbf6"
subnet_ids = ["subnet-066d0c78479b72e77"]

instance_type  = "t3.medium"
instance_count = 1
volume_size    = 30

allowed_cidr_blocks = ["10.0.0.0/16"]
admin_password      = "YourSecurePassword123!"

enable_clustering = false

tags = {
  Project     = "MyApp"
  Owner       = "DevTeam"
  CostCenter  = "12345"
}