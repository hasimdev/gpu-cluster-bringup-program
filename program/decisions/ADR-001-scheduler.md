# ADR-001: Job scheduler for the GPU cluster

**Status:** Proposed
**Date:** 2026-11-15
**Decider:** Program TPM, with the Research Lead consulted

## Context

Researchers need to submit training jobs, wait their turn when the GPUs are busy, and get a fair share of capacity. The cluster already runs Kubernetes, because the NVIDIA GPU Operator needs it to manage drivers and the device plugin. The question is which queueing layer sits on top.

The two serious options are Kueue (a Kubernetes-native job queue) and Slurm (the traditional HPC scheduler, which most research teams already know).

## Options

### Option A: Kueue

Kueue admits Kubernetes Jobs into the cluster according to quotas defined in ClusterQueues and LocalQueues.

Pros:
- Runs natively on Kubernetes, so there's one control plane to operate
- Works with the PyTorch Job / JobSet ecosystem and plain Jobs
- Quotas, borrowing between queues and priorities are built in
- Small footprint: one controller deployment

Cons:
- Researchers have to write YAML or use a wrapper script instead of `sbatch`
- Smaller community than Slurm, and fewer people with operating experience
- Multi-node job launch depends on the job type (JobSet or the Kubeflow Training Operator), which adds a component

### Option B: Slurm (on Kubernetes or alongside it)

Pros:
- Most researchers already know `sbatch`, `srun` and `squeue`
- Mature handling of multi-node jobs, fair-share and accounting
- Standard in HPC and in many large GPU clusters

Cons:
- Running Slurm next to Kubernetes means two schedulers that both believe they own the GPUs, unless one is carved out for the other
- Running Slurm inside Kubernetes (e.g. via an operator) is newer and less proven
- More moving parts for a two-node cluster: slurmctld, slurmd, a database for accounting

## Tradeoffs that matter for this program

| Factor | Kueue | Slurm |
|---|---|---|
| Fits the existing Kubernetes platform | Yes | Partly, needs integration work |
| Researcher familiarity | Low | High |
| Operating effort at 2 nodes | Low | Medium–High |
| Multi-node PyTorch support | Through JobSet / Training Operator | Native via `srun` |
| Time to Gate 2 | Shorter | Longer |

## Proposed decision

Use Kueue for this program. The cluster is small, the four-week schedule is tight, and Kueue avoids running two schedulers over the same GPUs. The cost is researcher familiarity, which the onboarding guide and a thin submit script are meant to cover.

## What would change this

- If the onboarding test (Gate 4) shows researchers can't submit a job in under 30 minutes because of the YAML, revisit with Slurm or a better wrapper.
- If the cluster grows past roughly 16 nodes or needs detailed accounting, Slurm's maturity becomes more valuable.

## Consequences

- Multi-node jobs are written as Kubernetes Jobs with an indexed completion mode, or as JobSets. The sample in `build/jobs/ddp-job.yaml` uses an indexed Job.
- The onboarding guide has to explain how to submit to a LocalQueue.

Once the Research Lead agrees, this status moves to **Accepted** and decision D2 in the RAID log gets its date.
