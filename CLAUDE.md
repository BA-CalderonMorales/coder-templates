# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Coder workspace templates for creating consistent, portable development environments that run on Docker containers. Templates support local Docker Desktop and cloud deployments (GCP, AWS, Azure) with an emphasis on free-tier/low-cost infrastructure.

## Core Development Commands

### Building and Packaging Templates

```bash
# Package template for upload to Coder (Linux)
./start.linux.sh

# macOS
./start.mac.sh

# Windows
./start.windows.sh
```

These scripts create `terminal-jarvis-playground.tar` containing the Terraform template and related files.

### Docker Image Management

```bash
# Build the workspace image locally
docker build -t coder-terminal-jarvis-playground:latest terminal-jarvis-playground/

# Verify the image builds successfully
docker images | grep coder-terminal-jarvis-playground

# Multi-arch build for ARM64 support (e.g., AWS t4g.micro)
docker buildx build --platform linux/amd64,linux/arm64 -t coder-terminal-jarvis-playground:latest terminal-jarvis-playground/
```

### Terraform Validation

```bash
# Validate Terraform configuration
cd terminal-jarvis-playground
terraform validate

# Format Terraform files
terraform fmt
```

## Architecture

### Template Structure

The repository uses a single-template structure currently focused on `terminal-jarvis-playground`:

- **Dockerfile**: Defines the development environment (Ubuntu base + Node.js 20 + Git)
- **main.tf**: Terraform configuration that provisions:
  - Coder agent with startup scripts and monitoring metadata
  - code-server module (VS Code in browser)
  - JetBrains Gateway module (IntelliJ, PyCharm, WebStorm, etc.)
  - Docker container with persistent home directory volume
  - Resource monitoring (CPU, RAM, disk, load average, swap)

### Provider Architecture

The template uses two Terraform providers:
- **coder/coder**: Workspace lifecycle management
- **kreuzwerker/docker**: Container and volume operations

### Persistence Model

- **Ephemeral**: Container itself (recreated on workspace restart)
- **Persistent**: Docker volume mounted at `/home/coder` (survives restarts)
- Tools installed outside `/home/coder` must be baked into the Dockerfile

### Key Design Principles

1. **Progressive Enhancement**: Start with code-server only, optionally enable JetBrains Gateway
2. **Resource Awareness**: Designed to run on 1 GiB RAM instances (with constraints)
3. **Multi-arch Support**: Targeting x86_64 and arm64 architectures
4. **Cloud Agnostic**: Same template works locally and on major cloud providers

## Deployment Models

Documented deployment guides exist for:
- **Docker Desktop** (`docs/deployment_models/DockerDesktop.md`): Local baseline, fast iteration
- **GCP** (`docs/deployment_models/GCP.md`): e2-micro, Always Free tier
- **AWS** (`docs/deployment_models/AWS.md`): t2.micro/t4g.micro, 12-month free tier
- **Azure** (`docs/deployment_models/Azure.md`): B1s, constrained CPU credits

See `docs/deployment_models/limitations.md` for comprehensive resource constraints.

## Critical Constraints

### Memory Limitations
- **1 GiB RAM instances** (GCP e2-micro, AWS t2/t4g.micro, Azure B1s) cannot reliably run JetBrains IDE backends
- JetBrains Gateway should default to disabled via feature flag for these environments
- Swap (1 GiB recommended) mitigates but doesn't eliminate OOM risks

### Image Size
- Target: < 1.2 GB compressed to minimize pull time and bandwidth costs on constrained instances
- Use multi-stage builds to remove build dependencies (planned)

### Architecture Support
- ARM64 support critical for AWS t4g instances and Apple Silicon local development
- Use `docker buildx` with `--platform linux/amd64,linux/arm64`

## Variable Management

When adding new Terraform variables to `main.tf`:
1. Document in root `README.md`
2. Update relevant deployment model docs in `docs/deployment_models/`
3. Provide sensible defaults that work without flags

Planned variables (not yet implemented):
- `enable_jetbrains_gateway`: Feature flag for JetBrains support
- `workspace_image`: Allow custom image references
- `cpu_limit`, `memory_limit`: Resource constraints

## Code Style Requirements

From `.github/copilot-instructions.md`:

- **NO EMOJIS**: Absolutely prohibited in code, docs, commit messages, PR titles/descriptions, or any generated output
- **Terraform Style**: Small, composable changes; document non-obvious defaults in comments
- **Documentation**: High-signal comments only; use semantic section headers; keep tables scannable
- **Defaults**: New features should work without requiring additional flags

## Planned Roadmap

1. Align Terraform with documented feature flag variables
2. Automated multi-arch image builds with GitHub Actions
3. Secret integration patterns (dotfiles, secret managers)
4. Additional deployment docs (DigitalOcean, Hetzner)
5. Lint/test harness (tflint, terraform validate, trivy/grype for image scanning)
6. devcontainer.json example for local VS Code attachment
7. Multi-stage Dockerfile optimization

## Git Configuration

The template automatically configures Git inside workspaces using owner metadata:
- `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`
- `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`

These are set via the coder_agent environment variables in `main.tf:77-82`.

## Monitoring and Observability

The template includes real-time dashboard metrics via coder_agent metadata blocks:
- CPU usage (container and host)
- RAM usage (container and host)
- Home disk usage
- Load average (scaled by core count)
- Swap usage

Scripts use `coder stat` commands and custom shell logic. See `main.tf:89-148`.
