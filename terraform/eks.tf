module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true
  create_iam_role                = false
  iam_role_arn                   = local.eks_service_role_arn
  enable_irsa                    = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_security_group_additional_rules = {
    egress_postgresql = {
      description = "Node egress to private PostgreSQL"
      protocol    = "tcp"
      from_port   = 5432
      to_port     = 5432
      type        = "egress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  eks_managed_node_groups = {
    default = {
      create_iam_role = false
      iam_role_arn    = local.eks_service_role_arn

      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.small"]
    }
  }

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
