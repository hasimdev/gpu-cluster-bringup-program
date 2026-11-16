# Launch Readiness Checklist

Launch happens at Gate 4. Each line needs evidence: a link, a screenshot or a log file in the repo. A line without evidence counts as unchecked.

## Infrastructure

- [ ] `terraform apply` from an empty state produces a working environment with no manual steps
- [ ] `terraform destroy` removes everything, and the AWS bill shows no stray resources afterward
- [ ] Auto-stop tested and confirmed working
- [ ] Budget alarm tested and routed to a monitored email address

## Platform

- [ ] All GPU Operator pods healthy on both nodes
- [ ] Driver, CUDA, PyTorch and NCCL versions match the agreed matrix (record them here)
- [ ] Queue and quotas configured. A job over quota waits instead of running.

## Acceptance

- [ ] Multi-node DDP job completes through the queue
- [ ] Throughput recorded for 1 GPU and 2 GPUs, scaling efficiency calculated
- [ ] 24-hour burn-in average GPU utilization at or above 95%
- [ ] Zero XID errors during burn-in

## Observability

- [ ] Grafana dashboard shows utilization, memory, temperature and power per GPU
- [ ] At least one alert defined (e.g. GPU idle for 2 hours while a node is running)

## Users

- [ ] Onboarding guide published
- [ ] An outside tester submitted a first job in under 30 minutes (record the time)
- [ ] Known limitations documented (no high-speed interconnect, two nodes only)

## Program close

- [ ] Benchmark and cost table in the README filled with measured numbers
- [ ] RAID log up to date, every open risk either closed or handed to an owner
- [ ] Postmortem / retrospective written
- [ ] Final exec status sent

## Go / no-go

| Role | Go / No-go | Notes |
|---|---|---|
| TPM | | |
| Infra Eng | | |
| Research Lead | | |
| Security | | |
