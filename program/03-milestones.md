# Milestones and Gates

Each phase ends with a go/no-go gate. A gate passes only when every criterion has evidence behind it (a screenshot, a log, a Grafana link). If a gate fails, the program does not move on. It either fixes the gap or the TPM takes a decision to the stakeholders, recorded in the RAID log.

## Phase 0: Kickoff (Week 1, days 1–2)

| Item | Owner |
|---|---|
| Charter reviewed and agreed | TPM |
| GPU quota request filed with AWS | Infra Eng |
| Budget alarm created and tested | TPM / Finance |
| Version matrix drafted (driver, CUDA, PyTorch, NCCL) | Infra Eng |

**Gate 0:** Charter signed off, quota request submitted, budget alarm fires on a test threshold.

## Phase 1: Infrastructure (Week 1, days 3–5)

| Item | Owner |
|---|---|
| Terraform applies cleanly from an empty account | Infra Eng |
| Both nodes reachable and `nvidia-smi` shows one A10G each | Infra Eng |
| Auto-stop tested: an idle instance stops on schedule | Infra Eng |

**Gate 1:** `terraform destroy` then `terraform apply` rebuilds the environment with no manual steps. Both GPUs visible.

## Phase 2: Platform (Week 2)

| Item | Owner |
|---|---|
| Kubernetes cluster up with two GPU workers | Infra Eng |
| GPU Operator installed, all operator pods healthy | Infra Eng |
| A single-GPU test pod runs `nvidia-smi` successfully | Infra Eng |
| Scheduler decision taken (ADR-001 moves from proposed to accepted) | TPM |
| Queue and quotas configured | Infra Eng |

**Gate 2:** A job submitted through the queue lands on a GPU node and completes. ADR-001 accepted.

## Phase 3: Observability and acceptance (Week 3)

| Item | Owner |
|---|---|
| DCGM exporter, Prometheus and Grafana deployed | Infra Eng |
| Dashboard shows utilization, memory, temperature, power per GPU | Infra Eng |
| Multi-node DDP job runs across both nodes | Infra Eng |
| Throughput recorded for 1 GPU and 2 GPUs (scaling efficiency) | TPM |
| 24-hour burn-in started | Infra Eng |

**Gate 3:** DDP job passes, burn-in averages at least 95% GPU utilization over 24 hours, zero XID errors.

## Phase 4: Onboarding and launch (Week 4)

| Item | Owner |
|---|---|
| Onboarding guide written | Research Lead |
| Someone outside the build team follows the guide and submits a job, timed | TPM |
| Launch readiness checklist complete | TPM |
| Benchmark and cost table filled in with measured numbers | TPM |
| Retrospective / postmortem written | TPM |

**Gate 4 (launch):** First-job time under 30 minutes, every launch readiness item checked, spend within budget.

## Schedule at a glance

| Week | Phase | Gate |
|---|---|---|
| 1 | Kickoff, Infrastructure | Gate 0, Gate 1 |
| 2 | Platform | Gate 2 |
| 3 | Observability and acceptance | Gate 3 |
| 4 | Onboarding and launch | Gate 4 |

Actual dates and any slips go in the weekly status updates under [status/](status/).
