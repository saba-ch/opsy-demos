# Opsy Infrastructure Demos

Terraform demos for testing Opsy infrastructure monitoring and troubleshooting capabilities.

## Demos

| Demo | Description |
|------|-------------|
| [eks-demo](./eks-demo) | EKS cluster with Karpenter autoscaling |
| [peering-demo](./peering-demo) | VPC peering between two VPCs with EC2 instances |

## Usage

Each demo is a standalone Terraform project. Navigate to the demo directory and run:

```bash
cd <demo-name>
terraform init
terraform plan
terraform apply
```

## Cleanup

```bash
terraform destroy
```
