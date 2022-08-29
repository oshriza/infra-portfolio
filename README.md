# AWS EKS with Terraform
This project is part of develeap portfolio and provisiniong cluster on AWS
The project includes ArgoCD applications and configuration for CD pipeline 


## Run and Test

```bash
terraform apply
```
```bash
aws eks --region us-east-2 update-kubeconfig --name ${env_prefix}-default_cluster
```
