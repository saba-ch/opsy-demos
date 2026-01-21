# EKS Cluster Upgrade Runbook

This runbook describes the steps to upgrade the EKS cluster from one Kubernetes version to the next.

## Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl configured to access the cluster
- Terraform installed and initialized
- Sufficient IAM permissions for EKS and EC2 operations

## Upgrade Steps

### Step 1: Upgrade EKS Control Plane via AWS CLI

Initiate the EKS cluster control plane upgrade to the target Kubernetes version using the AWS CLI. Monitor the upgrade status until the cluster returns to `ACTIVE` state before proceeding to the next step.

### Step 2: Upgrade Node Groups via AWS CLI

Upgrade the node groups via the AWS CLI. Monitor the upgrade status until the node groups return to `ACTIVE` state before proceeding to the next step.

### Step 3: Sync Terraform and Upgrade Add-ons

Update the `cluster_version` variable in Terraform to match the new version. Run `terraform plan` to review the changes (primarily add-on upgrades), then `terraform apply` to upgrade the EKS add-ons (CoreDNS, kube-proxy, VPC CNI, etc.) to versions compatible with the new cluster version.

### Step 4: Verify Cluster Health

Confirm all nodes are in `Ready` state and running the target Kubernetes version. Verify all pods across namespaces are in `Running` or `Completed` state. Check that EKS add-ons are upgraded to the expected versions.

**Upgrade Order:** Control Plane → Node Groups → Add-ons → Validation
