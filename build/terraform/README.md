# Terraform: GPU nodes and cost guardrails

Creates two g5.xlarge instances (one A10G each) in the default VPC, a security group that lets the nodes talk to each other freely, a monthly AWS budget with email alerts, and an idle auto-stop alarm per instance.

## Before you run it

1. Request a quota increase for "Running On-Demand G and VT instances" in your region. Two g5.xlarge need 8 vCPUs. New accounts often start at 0. This is the program's critical path (RAID R1), so file it first.
2. Create an EC2 key pair and note its name.
3. Activate the `Project` cost allocation tag in the Billing console, otherwise the budget filter sees no spend. Tags can take up to 24 hours to show up there.

## Run

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit
terraform init
terraform plan
terraform apply
```

Tear everything down at the end of each working session if you aren't running the burn-in:

```bash
terraform destroy
```

## Auto-stop

There are two layers, because forgetting a running GPU instance is the most likely way to blow the budget.

- **Idle alarm (in this code).** A CloudWatch alarm stops each instance after `idle_stop_minutes` of CPU under 5%. It watches CPU, not GPU. See the comment in `cost-guardrails.tf` for the limits of that.
- **End-of-day habit (not in code).** Run `terraform destroy`, or stop the instances, when you're done for the day. Stopped instances still bill for their EBS volumes, at roughly $12 a month per 150 GB gp3 disk.

Stopping an instance and starting it again usually moves it to different physical hardware. That's also the fix if a node shows XID errors during burn-in (RAID R7).

## After apply

Install Kubernetes on the nodes (kubeadm or k3s, with node 0 as the control plane), then follow `../k8s/` for the GPU Operator and Kueue.
