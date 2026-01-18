module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  # Managed node groups - locked to cluster version
  eks_managed_node_groups = {
    default = {
      name           = "default-ng"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      # Lock to specific version
      ami_type        = "AL2023_x86_64_STANDARD"
      release_version = null # Uses the AMI for the specified cluster version

      # Required for public subnet nodes
      associate_public_ip_address = true

      labels = {
        "node-type" = "managed"
      }

      tags = {
        "karpenter.sh/discovery" = var.cluster_name
      }
    }
  }

  # Enable Karpenter discovery
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = var.tags
}
