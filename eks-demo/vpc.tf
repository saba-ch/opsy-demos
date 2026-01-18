data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs            = local.azs
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]

  # No private subnets, no NAT gateway
  enable_nat_gateway = false
  single_nat_gateway = false

  # Auto-assign public IPs for public subnets (required for EKS nodes)
  map_public_ip_on_launch = true

  # Required for EKS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS and Karpenter
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  tags = var.tags
}
