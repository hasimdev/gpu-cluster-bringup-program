# GPU monitoring: DCGM exporter, Prometheus, Grafana

The GPU Operator already deploys DCGM exporter on every GPU node (`dcgmExporter.enabled: true` in `../k8s/gpu-operator-values.yaml`). What's left is a Prometheus to scrape it and a Grafana to show it.

## Install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

That last flag lets Prometheus pick up the ServiceMonitor the GPU Operator creates. Without it, Prometheus ignores ServiceMonitors from other Helm releases and the GPU panels stay empty, which is easy to mistake for a DCGM problem.

Install the monitoring stack before the GPU Operator, or upgrade the operator afterward, so the ServiceMonitor CRD exists when the operator tries to create one.

## Dashboard

Import NVIDIA's DCGM exporter dashboard into Grafana (Grafana.com dashboard ID 12239), then check that every GPU shows up.

## Metrics the program relies on

| Metric | Used for |
|---|---|
| `DCGM_FI_DEV_GPU_UTIL` | Burn-in success criterion (24h average at or above 95%) |
| `DCGM_FI_DEV_FB_USED` | Spotting jobs that run out of GPU memory |
| `DCGM_FI_DEV_GPU_TEMP` | Thermal check during burn-in |
| `DCGM_FI_DEV_POWER_USAGE` | Confirms the GPU is actually working hard, not just "allocated" |
| `DCGM_FI_DEV_XID_ERRORS` | Burn-in success criterion (zero XID errors) |

## Burn-in query

Average utilization across all GPUs over the burn-in window:

```promql
avg(avg_over_time(DCGM_FI_DEV_GPU_UTIL[24h]))
```

Any XID errors in the same window:

```promql
max_over_time(DCGM_FI_DEV_XID_ERRORS[24h]) > 0
```

Save screenshots of both results into `../../evidence/` for Gate 3.

## Suggested alert

A node is running but its GPU has been idle for two hours, which means money is being spent for nothing:

```promql
avg_over_time(DCGM_FI_DEV_GPU_UTIL[2h]) < 5
```
