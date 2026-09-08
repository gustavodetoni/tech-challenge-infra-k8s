terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  aws_academy_service_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.aws_academy_service_role_name}"
  eks_service_role_arn         = var.eks_service_role_arn != "" ? var.eks_service_role_arn : local.aws_academy_service_role_arn
}
