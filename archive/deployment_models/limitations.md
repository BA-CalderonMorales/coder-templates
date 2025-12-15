# Deployment Model Limitations & Constraints

This living document tracks discovered limitations, resource ceilings, and caveats across supported environments. Update it whenever a new constraint or workaround is identified.

## Legend
| Severity | Meaning |
|----------|---------|
| Info | Mild consideration, low impact |
| Warning | Noticeable impact or configuration requirement |
| Critical | Blocks feature or causes failure without mitigation |

## Summary Table
| Area | Docker Desktop | GCP e2-micro | AWS t2/t4g.micro | Azure B1s | Notes |
|------|----------------|-------------|------------------|-----------|-------|
| Total RAM | Host-dependent | ~1 GiB | 1 GiB | 1 GiB | JetBrains disabled on 1 GiB class |
| JetBrains Gateway | Supported (>=4 GiB host) | Critical (disable) | Critical (disable) | Critical (disable) | Needs >=2–3 GiB RAM |
| code-server | Stable | Stable (light extensions) | Stable | Stable | Keep extensions minimal |
| Multi-Arch Image Need | Optional | Optional | Warning (t4g) | Optional | Buildx for arm64 |
| Swap Recommended | Optional | Warning (1G swap) | Warning (1G swap) | Warning (1G swap) | Mitigates OOM |
| Disk Default | Host FS | 30 GB PD | 30 GB EBS | 30 GB OS Disk | Clean layers & caches |
| Network Egress Cost | None | Warning | Warning | Warning | Limit large image pulls |
| Startup Latency | Fast | Moderate (cold CPU) | Moderate | Moderate | Pre-pull images |

## Detailed Notes
### JetBrains Gateway
Memory footprint of backend processes exceeds practical limits on 1 GiB instances. Recommendation: feature flag off by default (`enable_jetbrains_gateway=false`).

### Swap Usage
Adding 1 GiB swap reduces abrupt OOM kills during dependency compilation; still not a substitute for real RAM.

### Image Size
Target < 1.2 GB compressed. Large images slow pulls on constrained bandwidth / credits.

### Multi-Arch Builds
Required only when targeting ARM (AWS t4g.*) or Apple Silicon local dev; use `docker buildx` with `--platform linux/amd64,linux/arm64`.

### Disk Pressure
Layer accumulation + package caches can exceed free quotas. Implement periodic pruning in future automation (`docker system prune --filter "until=168h"`).

### Security
Never expose unauthenticated Coder or plain Docker TCP. Future: add docs section for reverse proxy hardening.

## Planned Mitigations
| Limitation | Mitigation | Status |
|-----------|------------|--------|
| JetBrains disabled on micro | Feature flag; docs guidance | Done |
| OOM risk on builds | Add swap instructions | Done |
| Image size creep | Multi-stage slimming | Planned |
| Manual pruning | Add maintenance script | Planned |
| Lack of CI validation | Add GitHub Actions (tflint, validate) | Planned |

---
Last updated: 2025-09-18
