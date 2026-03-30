# Coder Templates

Terraform-based workspace templates for the Terminal-Jarvis development environment. They are portable across Docker and cloud providers, and focus on low-cost defaults with pre-configured toolchains (Node.js 20, Python 3, Rust, and common utilities).

This repository is currently a temporary placeholder while content migrates into the `my-life-as-a-dev` project. Legacy materials live in `archive/` to ease that handoff.

## Table of Contents

- [Quick links](#quick-links)
- [Repository scope](#repository-scope)
- [What's included](#whats-included)
- [Templates at a glance](#templates-at-a-glance)
- [Workflow](#workflow)
- [Resource and observability essentials](#resource-and-observability-essentials)
- [Documentation source of truth](#documentation-source-of-truth)
- [Doc drift prevention & maintenance](#doc-drift-prevention--maintenance)
- [Development and validation](#development-and-validation)
- [License](#license)


> *Note: If these links do not respond in the GitHub Mobile app, try viewing in a browser. This is a known platform limitation.*

## Quick links

- Packaging scripts: `./package.{linux|mac|windows}.sh`
- Templates: `terminal-jarvis-playground/local-docker` and `terminal-jarvis-playground/gcp`
- Canonical documentation (source of truth): https://BA-CalderonMorales.github.io/my-life-as-a-dev/projects/active/coder-templates/
- Legacy in-repo materials (temporary placeholder for migration): `archive/`

## Repository scope

- Centralized home for multiple Coder templates (not just Terminal-Jarvis).
- Originated as a way to validate the Terminal-Jarvis workspace; now tracks additional and future templates in one place.

## What's included

**Implemented**
- Local Docker template with persistent volumes
- GCP Compute Engine template using bare VM architecture
- Cross-platform packaging scripts
- Devcontainer for contributors
- Built-in resource monitoring/observability

**Planned**
- Feature flags for optional components (JetBrains Gateway, resource limits)
- Multi-architecture image builds (AMD64 + ARM64) via GitHub Actions
- AWS and Azure template implementations (docs exist; Terraform pending)
- Automated linting and validation pipeline (tflint, trivy/grype)
- Secret management patterns (dotfiles, cloud secret managers)

See `AGENTS.md` for AI agent guidance and repository workflow expectations.

## Templates at a glance

| Template | Target | Highlights | Docs |
|----------|--------|------------|------|
| `local-docker` | Docker Desktop/Engine | Persistent `/home/coder` volume, code-server, JetBrains Gateway support, automatic git config from Coder metadata | `terminal-jarvis-playground/local-docker/README.md` |
| `gcp` | GCP Compute Engine (Always Free friendly) | Bare VM (no Docker dependency), systemd-managed Coder agent, optional Docker + Archestra.ai, persistent root disk | `terminal-jarvis-playground/gcp/README.md` |

Key variables:
- `local-docker`: `docker_socket` (optional override)
- `gcp`: `project_id` (required), `zone` (`us-central1-a` default), `machine_type` (`e2-micro` default), `disk_size` (`30` GB default), `gcp_credentials` (optional service account JSON key; falls back to ambient credentials), `enable_archestra` (default `false`), `enable_docker` (default `false`)

## Workflow

1. **Package a template**
   ```bash
   ./package.linux.sh            # Interactive menu
   ./package.linux.sh local-docker   # Creates terminal-jarvis-playground-local.tar
   ./package.linux.sh gcp            # Creates terminal-jarvis-playground-gcp.tar
   ./package.linux.sh all            # Builds both
   ```
2. **Upload to Coder**
   1. Templates → Create Template
   2. Upload the `.tar`
   3. Configure template variables (see template README)
   4. Create a workspace

## Resource and observability essentials

- Memory: 2+ GiB recommended for code-server; 4+ GiB for JetBrains Gateway; add ~1 GiB swap for 1 GiB class instances (e.g., e2-micro, t2.micro, B1s).
- CPU: burstable credits on AWS t2/t4g and Azure B1s can throttle sustained workloads.
- Disk: target workspace image < 1.2 GB compressed; GCP Always Free offers 30 GB standard PD.
- Architecture: ARM64 support matters for AWS t4g and Apple Silicon; use `docker buildx --platform linux/amd64,linux/arm64`.
- Observability: dashboard metrics include CPU, RAM, disk, load, and swap (see `main.tf` in `local-docker` for implementation).

See `archive/deployment_models/limitations.md` for platform-specific caveats. These values mirror the external documentation; update both locations together when constraints change.

## Documentation source of truth

- Primary docs now live at: https://BA-CalderonMorales.github.io/my-life-as-a-dev/projects/active/coder-templates/
- The `archive/` folder contains legacy reference content as a temporary placeholder while material migrates into https://github.com/BA-CalderonMorales/my-life-as-a-dev; prefer updating the external site first, then mirror only the minimal pointers needed here.
- Template READMEs stay in-repo for deployment specifics; keep them consistent with the external site.
- If the external site is unavailable, fall back to template READMEs and `archive/` until it is restored.
- Use `archive/` for short link lists or operational notes only; full deployment guides and explanations should live on the external site. Migration is ongoing, so move narrative content out of `archive/` when you touch it.

## Doc drift prevention & maintenance

1. Treat the external site as the canonical source. When changing templates, open a companion PR (a docs PR shipped alongside the template change) in the documentation site repository (currently https://github.com/BA-CalderonMorales/my-life-as-a-dev) and update the corresponding page there. Adjust the repository reference here if the docs site ever moves.
2. Cross-link the two PRs and note the docs update in the changelog or commit message.
3. Keep `archive/` limited to brief pointers/operational notes until migration is complete; avoid duplicating full guides.
4. During releases or notable template changes, run a quick docs check: verify README links to the external site, confirm variable defaults match Terraform, and update `archive/deployment_models/limitations.md` if resource ceilings change.
5. When possible, automate syncs (link checks or generated docs) so the manual steps above become verification rather than authoring.

## Development and validation

```bash
# Validate Terraform for a template
cd terminal-jarvis-playground/{template-name}
terraform init
terraform validate
terraform fmt -check

# (Optional) Build Docker image during local iteration
docker build -t test-image:latest .
```

Use the devcontainer (`.devcontainer/`) for a consistent contributor environment. Follow `.github/copilot-instructions.md` and `AGENTS.md` for style guidance (no emojis, concise comments, semantic doc headers).

## License

See `LICENSE` for details.

---
*Last synced: 2026-03-30 via [workspace ecosystem](https://github.com/BA-CalderonMorales)*
