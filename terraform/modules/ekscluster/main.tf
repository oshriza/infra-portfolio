locals {
  subnets = concat(var.private_subnets, var.public_subnets)
  node_policy_list = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}

resource "aws_iam_role" "oshri_iamrole" {
  name = "${var.env_prefix}-eks_iam_role"
  assume_role_policy = file("./modules/ekscluster/utils/aws_eks_role.json")
}

resource "aws_iam_role_policy_attachment" "oshri_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.oshri_iamrole.name
}

resource "aws_eks_cluster" "oshri_cluster" {
  name     = "${var.env_prefix}_cluster"
  role_arn = aws_iam_role.oshri_iamrole.arn

  vpc_config {
    subnet_ids = [for i, v in local.subnets : local.subnets[i].id]
  }

  depends_on = [aws_iam_role_policy_attachment.oshri_AmazonEKSClusterPolicy]
}

resource "aws_iam_role" "oshri_nodes_iamrole" {
  name = "${var.env_prefix}_node_iam_role"
  assume_role_policy = file("./modules/ekscluster/utils/aws_ec2_role.json")
}

resource "aws_iam_role_policy_attachment" "nodes_eks_iamrole" {
  count = length(local.node_policy_list)
  policy_arn = local.node_policy_list[count.index]
  role       = aws_iam_role.oshri_nodes_iamrole.name
}

resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.oshri_cluster.name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.oshri_nodes_iamrole.arn

  subnet_ids = [for i, v in var.private_subnets: var.private_subnets[i].id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]

  scaling_config {
    desired_size = 3
    max_size     = 6
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # labels = {
  #   role = "general"
  # }

  # taint {
  #   key    = "team"
  #   value  = "devops"
  #   effect = "NO_SCHEDULE"
  # }

  # launch_template {
  #   name    = aws_launch_template.eks-with-disks.name
  #   version = aws_launch_template.eks-with-disks.latest_version
  # }

  depends_on = [aws_iam_role_policy_attachment.nodes_eks_iamrole]
}

# resource "aws_launch_template" "eks-with-disks" {
#   name = "eks-with-disks"

#   key_name = "local-provisioner"

#   block_device_mappings {
#     device_name = "/dev/xvdb"

#     ebs {
#       volume_size = 50
#       volume_type = "gp2"
#     }
#   }
# }





# data "tls_certificate" "oshri_cert" {
#   url = aws_eks_cluster.oshri_cluster.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "oshri_openid" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.oshri_cert.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.oshri_cluster.identity[0].oidc[0].issuer
# }

# data "aws_iam_policy_document" "test_oidc_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.oshri_openid.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:default:aws-test"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.oshri_openid.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "test_oidc" {
#   assume_role_policy = data.aws_iam_policy_document.test_oidc_assume_role_policy.json
#   name               = "${var.env_prefix}-oidc"
# }

# resource "aws_iam_policy" "test-policy" {
#   name = "${var.env_prefix}-bucket-policy"
#   policy = file("./modules/ekscluster/utils/aws_iam_policy_bucket.json")
# }

# resource "aws_iam_role_policy_attachment" "test_attach" {
#   role       = aws_iam_role.test_oidc.name
#   policy_arn = aws_iam_policy.test-policy.arn
# }
