# Copilot Guidance: Project Direction & Strategy

This document is for AI assistants helping evolve this repository. It explains intent, priorities, architectural direction, and how to propose or implement changes safely.

## Vision
Provide a set of portable, cloud-agnostic Coder workspace templates that:
- Run locally (Docker Desktop) and on low-cost / free-tier infrastructure (GCP, AWS, Azure)
- Offer progressive enhancement: start lean (code-server only) → scale to richer IDE support (JetBrains Gateway)
- Are reproducible, minimal, and observable (resource metadata, health stats)
- Encourage multi-arch image support (x86_64 + arm64)

## Environments (Current & Target)
| Environment | Status | Notes |
|-------------|--------|-------|
| Docker Desktop (local) | Initial baseline | Fast iteration, no cloud cost |
| GCP e2-micro | Documented | Always-free, memory constrained |
| AWS t2/t4g.micro | Documented | 12-month free tier only |
| Azure B1s | Documented | Constrained CPU credits |
| Additional (DigitalOcean, Hetzner, Fly.io) | Planned | Add if demand & cost justification |

## Key Constraints
- 1 GiB RAM class targets cannot reliably run JetBrains IDE backends → default disabled.
- Must keep Terraform template readable; avoid over-abstracting prematurely.
- Avoid hidden costs: large base images, unnecessary network pulls.
- All docs must reference any new variables introduced.

## Roadmap (Incremental)
1. Align Terraform with documented variables (feature flags, resource limits)
2. Introduce automated multi-arch image build workflow (GitHub Actions) with caching
3. Add optional secrets integration patterns (e.g., mounting dotfiles repo or pulling from secret managers)
4. Provide DigitalOcean & Hetzner deployment docs
5. Add lint/test harness for Terraform (tflint + terraform validate) & Docker image vulnerability scan (grype or trivy)
6. Add example devcontainer.json synergy for local VS Code attachment
7. Implement workspace image slimming (multi-stage build, remove build deps)

## Style & Contribution Guidelines
- Prefer small, composable Terraform changes; group related variable additions.
- Document new variables in README and relevant deployment docs.
- Keep comments high-signal; remove stale / duplicate commentary.
- Use semantic section headers in docs; keep tables narrow and scannable.
- Provide reasoning for non-obvious defaults (in comments or docs).
- Absolutely NO emojis (🚫). Do not include emojis in code, docs, commit messages, PR titles/descriptions, or generated outputs. Maintain a professional, concise technical tone.

## Copilot / AI Task Patterns
| Task Type | Expected Output |
|-----------|-----------------|
| Add variable | Modify `main.tf`, update README + doc references |
| New deployment model | New markdown in `docs/deployment_models/` + README link |
| Optimize image | Update Dockerfile + note change in README and docs |
| Add CI | `.github/workflows/*.yml` with clear job naming |

## Testing & Validation
- Run `terraform validate` after any Terraform change.
- Keep Docker image buildable via: `docker build -t coder-terminal-jarvis-playground:latest terminal-jarvis-playground/`.
- Avoid breaking existing variable-less usage (defaults should work without extra flags).

## Limitations Tracking
See `docs/deployment_models/limitations.md` for evolving constraints. Update when discovering new resource ceilings or incompatibilities.

## Security Considerations
- Never expose Docker daemon without TLS.
- Encourage HTTPS termination in docs for any public endpoint.
- Avoid embedding secrets; prefer environment variables or secret stores.

## When Unsure
Prefer drafting a proposal section inside the relevant doc or opening a PR with a concise rationale block:
```
## Rationale
Problem: <what>
Constraints: <memory, cost, portability>
Proposed Change: <summary>
Alternatives Considered: <short list>
Impact: <positive/negative>
```

## Non-Goals (For Now)
- Full Kubernetes orchestration
- Autoscaling fleets of workspaces
- Multi-tenant resource quota enforcement (left to Coder platform / infra layer)

---
Last updated: 2025-09-18
