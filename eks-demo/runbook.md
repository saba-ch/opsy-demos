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

### Step 2: Monitor Karpenter Nodes Upgrade

After the control plane version changes, Karpenter will automatically detect the version drift and begin rolling nodes to match the new cluster version. Monitor the node replacements and Karpenter logs until all Karpenter-managed nodes are running the new Kubernetes version.

### Step 3: Upgrade AWS Managed Node Groups

Once Karpenter nodes are fully upgraded, proceed with upgrading AWS managed node groups via the AWS CLI. Upgrade each node group and wait until all node groups return to `ACTIVE` status.

### Step 4: Sync Terraform and Upgrade Add-ons

Update the `cluster_version` variable in Terraform to match the new version. Run `terraform plan` to review the changes (primarily add-on upgrades), then `terraform apply` to upgrade the EKS add-ons (CoreDNS, kube-proxy, VPC CNI, etc.) to versions compatible with the new cluster version.

### Step 5: Verify Cluster Health

Confirm all nodes are in `Ready` state and running the target Kubernetes version. Verify all pods across namespaces are in `Running` or `Completed` state. Check that EKS add-ons are upgraded to the expected versions.

---

## Summary

| Step | Action | Verification |
|------|--------|--------------|
| 1 | Upgrade EKS control plane via AWS CLI | Cluster status is `ACTIVE` |
| 2 | Monitor Karpenter node replacements | All Karpenter nodes on new version |
| 3 | Upgrade AWS managed node groups | All node groups status `ACTIVE` |
| 4 | Terraform plan/apply to upgrade add-ons | Add-ons upgraded successfully |
| 5 | Verify cluster health | All nodes Ready, all pods Running |

**Upgrade Order:** Control Plane → Karpenter Nodes (automatic) → Managed Node Groups → Add-ons → Validation

**Rollback Considerations:**
- EKS control plane upgrades cannot be rolled back
- Node groups can be rolled back by updating to previous AMI
- Add-ons can be downgraded via Terraform
- Always test upgrades in a non-production environment first
