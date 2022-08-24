provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


module "network" {
  source = "./modules/network"
  env_prefix            = "${var.env_prefix}-${terraform.workspace}"
  aws_availability_zone = var.aws_availability_zone
}

module "ekscluster" {
  source           = "./modules/ekscluster"
  vpc_id           = module.network.vpc
  # test_policy_arn  = module.ekscluster.test_policy_arn
  private_subnets  = module.network.private_subnets
  public_subnets   = module.network.public_subnets
  env_prefix       = "${var.env_prefix}-${terraform.workspace}"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  create_namespace = true
  namespace        = "argocdeks"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt("12345678")
  }
  depends_on = [
    module.ekscluster,
    module.network
  ]
}