# EKSクラスタリソースを参照
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

module "eks" {
  source                  = "terraform-aws-modules/eks/aws"
  version                 = "18.0.5"
  cluster_version         = "1.21"
  cluster_name            = "test-k8s"
  vpc_id                  = var.vpc_id
  subnet_ids              = var.private_subnets
  enable_irsa             = true
  eks_managed_node_groups = {
    test_node = {
      desired_size = 2
      instance_types   = ["t3.small"]
    }
  }
  # デフォルトのSecurityGroupでは動作しないため以下を追加
  node_security_group_additional_rules = {
    # AdmissionWebhookが動作しないので追加指定
    admission_webhook = {
      description = "Admission Webhook"
      protocol    = "tcp"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      source_cluster_security_group = true
    }
    # Node間通信を許可
    ingress_node_communications = {
      description = "Ingress Node to node"
      protocol    = "tcp"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    egress_node_communications = {
      description = "Egress Node to node"
      protocol    = "tcp"
      from_port   = 0
      to_port     = 65535
      type        = "egress"
      self        = true
    }
  }
}