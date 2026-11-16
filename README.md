# GPU Cluster Bring-Up Program

A small GPU training cluster taken from "capacity requested" to "researchers submit multi-node jobs through a queue," run the way a technical program manager would run a full-size bring-up: a charter, a dependency map, phase gates, a RAID log, decision records, weekly status and a launch checklist.

The cluster itself is deliberately small: two AWS g5.xlarge nodes with one NVIDIA A10G each, Kubernetes, the NVIDIA GPU Operator, Kueue, and DCGM monitoring. The program artifacts are the main deliverable. The build shows they were tested against real hardware.

Every number in this repo was measured on the cluster. Cells still marked "TBD, measured" haven't been run yet.

## Program artifacts

Start here.

| Document | What it covers |
|---|---|
| [Charter](program/01-charter.md) | Problem, scope, out of scope, success criteria, stakeholders, RACI, budget |
| [Dependency map](program/02-dependency-map.md) | What blocks what, the critical path, external dependencies |
| [Milestones and gates](program/03-milestones.md) | Four phases over four weeks, each ending in a go/no-go gate |
| [RAID log](program/04-raid-log.md) | Risks, assumptions, issues and decisions, kept up to date as the program runs |
| [Launch readiness](program/05-launch-readiness.md) | The checklist behind the final go/no-go |
| [ADR-001: Scheduler](program/decisions/ADR-001-scheduler.md) | Kueue vs Slurm, with the tradeoffs (proposed) |
| [Weekly status template](program/status/TEMPLATE-exec-status.md) | One-page exec update |
| [Postmortem template](program/postmortems/TEMPLATE.md) | Blameless incident review |

### Timeline

| Week | Phase | Gate |
|---|---|---|
| 1 | Kickoff and infrastructure | Gate 0: charter, quota filed, budget alarm tested. Gate 1: Terraform rebuilds cleanly, both GPUs visible |
| 2 | Platform | Gate 2: a queued job runs on a GPU, scheduler decision accepted |
| 3 | Observability and acceptance | Gate 3: multi-node DDP passes, 24h burn-in at 95%+ utilization, zero XID errors |
| 4 | Onboarding and launch | Gate 4: an outside tester submits a first job in under 30 minutes |

### Key decisions

| Decision | Status |
|---|---|
| g5.xlarge (1x A10G) as the node type, chosen on cost | Decided |
| Kueue over Slurm for job queueing | Proposed ([ADR-001](program/decisions/ADR-001-scheduler.md)) |
| Let the GPU Operator install drivers rather than baking them into the AMI, so versions live in one place | Decided |

## Build

```
build/
├── terraform/      2x g5.xlarge, security group, AWS budget alarm, idle auto-stop
├── k8s/
│   ├── gpu-operator-values.yaml
│   └── kueue/      ResourceFlavor, ClusterQueue, LocalQueue
├── monitoring/     DCGM exporter + Prometheus + Grafana notes and burn-in queries
└── jobs/
    ├── train_ddp.py   synthetic DDP throughput benchmark
    └── ddp-job.yaml   two-node indexed Job submitted through Kueue
```

Order of operations: [terraform](build/terraform/README.md) → install Kubernetes (kubeadm or k3s) → kube-prometheus-stack → GPU Operator → Kueue → run the [DDP job](build/jobs/ddp-job.yaml). See [monitoring notes](build/monitoring/dcgm-exporter.md) for the burn-in queries.

## Results

### Benchmark

Synthetic ResNet-style model, batch 64 per GPU, 128×128 images, bfloat16 autocast. Scaling efficiency is 2-GPU throughput divided by twice the 1-GPU throughput.

| Configuration | Samples/s | Samples/s per GPU | Scaling efficiency |
|---|---|---|---|
| 1 node × 1 A10G | TBD, measured | TBD, measured | baseline |
| 2 nodes × 1 A10G | TBD, measured | TBD, measured | TBD, measured |

g5.xlarge has no InfiniBand or cross-node NVLink, so gradients travel over ordinary Ethernet. Scaling efficiency is expected to be well under 100%. The real figure, and the reason for it, goes here.

### Burn-in

| Metric | Target | Result |
|---|---|---|
| Average GPU utilization over 24h | ≥ 95% | TBD, measured |
| XID errors | 0 | TBD, measured |
| Peak GPU temperature | n/a | TBD, measured |

### Onboarding

| Metric | Target | Result |
|---|---|---|
| Time for an outside tester to submit a first job | < 30 min | TBD, measured |

### Cost

| Item | Budget | Actual |
|---|---|---|
| EC2 compute | | TBD, measured |
| EBS storage | | TBD, measured |
| Data transfer | | TBD, measured |
| **Total** | $300 | TBD, measured |
| Cost of one 24h burn-in | | TBD, measured |
| Cost per 1M training samples | | TBD, measured |

## What went wrong

Filled in from the [RAID log](program/04-raid-log.md) issues and any [postmortems](program/postmortems/) once the program has run.

## Interview prep

[interview/star-stories.md](interview/star-stories.md) has a STAR outline for each major risk, to fill in with what actually happened.
