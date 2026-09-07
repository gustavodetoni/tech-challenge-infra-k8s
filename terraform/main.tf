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
  current_assumed_role_name = try(regex("^arn:aws:sts::[0-9]+:assumed-role/([^/]+)/.+$", data.aws_caller_identity.current.arn)[0], "")
  current_principal_arn     = local.current_assumed_role_name != "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.current_assumed_role_name}" : data.aws_caller_identity.current.arn
}
