# Program Charter: GPU Cluster Bring-Up

**Program TPM:** Abu Ansari
**Status:** Draft
**Last updated:** 2026-11-15

## Problem

A research team needs GPU capacity to train models across more than one machine. Today they rent single GPU instances ad hoc. Each person installs their own drivers and CUDA versions, nobody can see whether the GPUs are busy or idle, and multi-node training has never worked reliably. The cost of this shows up as wasted researcher time and idle hardware that still gets billed.

This program takes a small GPU cluster from "capacity requested" to "researchers submit jobs through a queue and can see what their jobs are doing."

## A note on scale

This is a portfolio program. It runs on two cloud GPU nodes instead of hundreds, and one person fills every role in the RACI below. The structure, gates and artifacts are the same ones a full-size bring-up would use, and that is the point of the exercise. Every number reported in this repo is measured on the real cluster. Nothing is estimated after the fact.

## Scope

In scope:

- Provisioning two GPU nodes on AWS (g5.xlarge, one NVIDIA A10G each) with Terraform
- A Kubernetes cluster with the NVIDIA GPU Operator handling drivers, the container toolkit and the device plugin
- A job queue with quotas so researchers share capacity fairly (see [ADR-001](decisions/ADR-001-scheduler.md))
- GPU monitoring with DCGM exporter, Prometheus and Grafana
- A multi-node PyTorch DDP job as the acceptance test
- A short onboarding guide and a cost guardrail (budget alarm plus auto-stop)

## Out of scope

- High-speed interconnects (InfiniBand, NVLink across nodes). g5.xlarge has neither, so the program accepts slower cross-node communication and documents the effect.
- Production security hardening such as SSO, network policies and secrets management beyond the basics
- Multi-tenant chargeback
- Model development. The acceptance test uses a synthetic benchmark, not a real research model.

## Success criteria

The program is done when all of these hold and the evidence is linked from the README:

1. A DDP training job runs across both nodes, submitted through the queue, and completes without manual intervention.
2. A 24-hour burn-in holds average GPU utilization at or above 95% with no XID errors in the DCGM logs.
3. A new user, following only the onboarding guide, submits a first job in under 30 minutes.
4. Grafana shows per-GPU utilization, memory, temperature and power for every node.
5. Spend for the whole program stays under the approved budget, and the budget alarm fires in a test before it is needed in earnest.

## Stakeholders

| Stakeholder | Interest |
|---|---|
| Research lead | Wants multi-node training working and fair access to GPUs |
| Infrastructure engineering | Builds and operates the cluster |
| Finance | Wants spend predictable and capped |
| Security | Needs access controlled and credentials kept out of the repo |
| Researchers (end users) | Want to submit a job without learning Kubernetes internals |

## RACI

R = Responsible, A = Accountable, C = Consulted, I = Informed

| Activity | TPM | Infra Eng | Research Lead | Finance | Security |
|---|---|---|---|---|---|
| Charter and scope | A/R | C | C | I | I |
| GPU quota request | A | R | I | C | I |
| Terraform provisioning | I | A/R | I | I | C |
| GPU Operator and drivers | I | A/R | I | I | I |
| Scheduler decision (ADR-001) | A | R | C | I | I |
| Monitoring stack | I | A/R | C | I | I |
| Acceptance test | A | R | C | I | I |
| Budget and cost guardrails | R | C | I | A | I |
| Onboarding guide | A | C | R | I | I |
| Launch go/no-go | A/R | C | C | I | C |

## Budget

Target ceiling: $300 for the whole program, covering bring-up, the 24-hour burn-in and benchmarking. Two g5.xlarge instances cost roughly $2 an hour together at on-demand prices (check current AWS pricing before relying on this figure). That leaves room for about 150 node-pair hours, so the auto-stop matters. Actual spend is tracked in the [RAID log](04-raid-log.md) and the weekly status.

## Timeline

Four weeks, with a gate at the end of each phase. Details in [03-milestones.md](03-milestones.md).
