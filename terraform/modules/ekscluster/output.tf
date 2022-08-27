# output "test_policy_arn" {
#   value = aws_iam_role.test_oidc.arn
# }

output "endpoint" {
    value = aws_eks_cluster.this.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}