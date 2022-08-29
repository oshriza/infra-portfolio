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

  depends_on = [aws_iam_role_policy_attachment.nodes_eks_iamrole]
}
