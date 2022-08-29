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


![eks-networking+CI CD](https://user-images.githubusercontent.com/24268589/187296973-a7a7e997-ea58-4c79-ac99-3117724d0abc.png)
