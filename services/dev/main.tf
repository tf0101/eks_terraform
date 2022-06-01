variable "aws_access_key" {}
variable "aws_secret_key" {}

terraform {
  required_version = "~> 1.0.8"

  # リモートステートの設定
  /*backend "s3" {
    bucket = "terraform-test-2022052704"
    key    = "eks-state"
    region = "ap-northeast-1"
  }*/
  # 実行するProviderの条件
  required_providers {
    aws       = {
      source  = "hashicorp/aws"
      version = "~> 3.71.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.5.0"
    }
  }
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region  = "ap-northeast-1"
}

data "aws_caller_identity" "self" {}

output "aws_user_id"{
    value ="${data.aws_caller_identity.self.account_id}"
    description = "aws user id"
}

module "vpc" {
    source = "../../modules/vpc"
}

module "eks" {
    source = "../../modules/eks"

    vpc_id          = module.vpc.vpc_id
    private_subnets = module.vpc.private_subnets
}

output "aws_auth_config_map"{
    value =module.eks.aws_auth_config_map
    description = "eks yaml"
}