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
  vpc_cidr = var.vpc_cidr
  vpc_prefix = var.vpc_prefix
}

module "ekscluster" {
  source           = "./modules/ekscluster"
  vpc_id           = module.network.vpc
  # test_policy_arn  = module.ekscluster.test_policy_arn
  private_subnets  = module.network.private_subnets
  public_subnets   = module.network.public_subnets
  env_prefix       = "${var.env_prefix}-${terraform.workspace}"
}

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }

provider "helm" {
  kubernetes {
    host                   = module.ekscluster.endpoint
    cluster_ca_certificate = base64decode(module.ekscluster.kubeconfig-certificate-authority-data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${var.env_prefix}-${terraform.workspace}_cluster"]
      command     = "aws"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocdeks"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version = "4.9.15"
  render_subchart_notes = true
  dependency_update = true
  create_namespace = true
  values = [
    file("./argocd/values-argo.yaml")
  ]

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
  # set {
  #   name  = "configs.secret.credentialTemplates.ssh-creds.sshPrivateKey"
  #   value = file(var.argocd_ssh_location)
  #   # "trimspace" func in order to remove spaces
  # }
  set {
    name  = "configs.credentialTemplates.ssh-creds.sshPrivateKey"
    value = file(var.argocd_ssh_location)
    # "trimspace" func in order to remove spaces
  }
  # set {
  #   name  = "configs.secret.argocdServerAdminPassword"
  #   value = bcrypt("12345678")
  # }
  depends_on = [
    module.ekscluster,
    module.network
  ]
}