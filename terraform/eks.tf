module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true
  create_iam_role                = false
  iam_role_arn                   = local.aws_academy_role_arn
  enable_irsa                    = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      create_iam_role = false
      iam_role_arn    = local.aws_academy_role_arn

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
