# RAID Log

Risks, Assumptions, Issues, Decisions.

**How this log is kept:** The risks below were identified before work started. Issues get logged only when they actually happen, with the date and what was done about them. If a risk turns into an issue, the risk row links to the issue row. Nothing here is backfilled to look tidier than it was.

Likelihood and impact use H / M / L.

## Risks

| ID | Risk | Likelihood | Impact | Mitigation | Owner | Status |
|---|---|---|---|---|---|---|
| R1 | AWS denies or delays the GPU quota increase, so no instances can launch | M | H | File the request on day one. Name a fallback region and a fallback instance family (g4dn) in the request notes. | Infra Eng | Open |
| R2 | Driver, CUDA and PyTorch versions don't match, so containers can't see the GPU or crash on start | M | H | Agree a version matrix before installing the GPU Operator. Pin operator and driver versions. Use an official PyTorch CUDA image. | Infra Eng | Open |
| R3 | Spend runs past budget because instances are left running overnight or during debugging | H | M | AWS budget alarm at 50%, 80% and 100%. Scheduled auto-stop outside working hours. Spend reviewed in every weekly status. | TPM | Open |
| R4 | NCCL can't connect across nodes (blocked ports, wrong network interface), so multi-node DDP hangs | M | H | Open intra-cluster traffic in the security group. Set `NCCL_SOCKET_IFNAME` explicitly. Run with `NCCL_DEBUG=INFO` on the first attempt. | Infra Eng | Open |
| R5 | Cross-node throughput is poor because g5.xlarge has no high-speed interconnect, and 2-GPU scaling looks bad | H | L | Accept it as a known limit (charter, out of scope). Measure and report scaling efficiency honestly, with the reason. | TPM | Open |
| R6 | Spot or on-demand capacity for g5 is unavailable in the chosen availability zone | L | M | Allow Terraform to pick from more than one subnet / AZ. | Infra Eng | Open |
| R7 | Burn-in fails on thermal or XID errors that point to a bad host | L | M | Replace the instance (stop/start moves it to new hardware) and rerun. Log the XID code. | Infra Eng | Open |

## Assumptions

| ID | Assumption | If it turns out wrong |
|---|---|---|
| A1 | One A10G per node is enough to prove multi-node behavior | Switch to g5.12xlarge (4 GPUs) for one day of testing, inside the budget |
| A2 | A synthetic benchmark is an acceptable acceptance test | Add a small real model (e.g. ResNet-50 on a public dataset) |
| A3 | On-demand pricing holds near the figure in the charter | Re-baseline the budget and tell Finance |
| A4 | A self-managed Kubernetes cluster (kubeadm or k3s) is acceptable instead of EKS | Move to EKS, which adds control plane cost |

## Issues

Logged only when they occur.

| ID | Date | Issue | Impact | Action taken | Owner | Status | Linked risk |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Decisions

| ID | Date | Decision | Rationale | Decided by | Record |
|---|---|---|---|---|---|
| D1 | 2026-11-15 | Use g5.xlarge (1x A10G) as the node type | Cheapest current-generation NVIDIA GPU instance that runs recent CUDA, fits the budget | TPM | Charter |
| D2 | TBD | Scheduler: Kueue or Slurm | Pending | TPM with Research Lead | [ADR-001](decisions/ADR-001-scheduler.md) (proposed) |
