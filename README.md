# Coder Templates

This repository contains templates and utilities for creating consistent development environments using Coder.

## Purpose

This repository provides multi-provider Coder templates for the Terminal-Jarvis development environment. Each provider has its own directory with tailored configurations for different deployment targets.

The workflow for using these templates:

1. Choose your deployment target (local Docker or cloud provider)
2. Navigate to the appropriate provider directory
3. Package the template into a `.tar` archive
4. Upload the generated `.tar` file to Coder as a new template
5. Coder uses this template to create consistent development environments for all team members

This ensures that every developer gets the same environment with all necessary tools (Node.js, Git, etc.) pre-configured, regardless of where it's deployed.

## Available Templates

### Terminal-Jarvis Playground

A development environment for Terminal-Jarvis with Node.js 20 and Git support.

**Providers:**

- **`local-docker/`** - Local Docker deployment with VS Code (code-server) and JetBrains IDE support
  - Best for local development and testing
  - Uses Docker Desktop or Docker Engine
  - See [local-docker/README.md](terminal-jarvis-playground/local-docker/README.md)

- **`gcp/`** - Google Compute Engine deployment with code-server
  - Ephemeral VM instances with persistent root disk
  - Always Free tier eligible (e2-micro)
  - Secure service account authentication with sensitive variable support
  - Code-server for browser-based VS Code
  - See [gcp/README.md](terminal-jarvis-playground/gcp/README.md)

## Quick Start

The easiest way to package templates is using the provided packaging scripts:

### Interactive Mode

Run the script without arguments to get a menu:

```bash
./package.linux.sh   # Linux
./package.mac.sh     # macOS
./package.windows.sh # Windows (Git Bash/WSL)
```

You'll see:
```
Available templates:
  1) local-docker - Local Docker deployment
  2) gcp - Google Compute Engine deployment
  3) all - Package both templates

Select template to package (1/2/3):
```

### Command-Line Mode

Pass the template name directly:

```bash
# Package specific template
./package.linux.sh local-docker  # Creates terminal-jarvis-playground-local.tar
./package.linux.sh gcp           # Creates terminal-jarvis-playground-gcp.tar
./package.linux.sh all           # Creates both tar files

# Or use numeric shortcuts
./package.linux.sh 1             # local-docker
./package.linux.sh 2             # gcp
./package.linux.sh 3             # both
```

### Next Steps

1. Run the packaging script for your chosen deployment target
2. Navigate to your Coder dashboard
3. Go to Templates → Create Template
4. Upload the generated `.tar` file
5. Configure template variables (see provider-specific README files)
6. Create a workspace from your template

## Template Structure

Each provider directory contains:
- `Dockerfile` - Defines the development environment image
- `main.tf` - Terraform configuration for the Coder workspace
- `README.md` - Provider-specific setup and usage instructions

## Cloud Deployment Models

Guides for running this template on common cloud free tiers / low-cost infrastructure are available:

- [Docker Desktop (Local Baseline)](docs/deployment_models/DockerDesktop.md)
- [GCP Deployment (Always Free)](docs/deployment_models/GCP.md)
- [AWS Deployment (Free Tier)](docs/deployment_models/AWS.md)
- [Azure Deployment (Free / Low-Cost)](docs/deployment_models/Azure.md)

Tracking constraints and resource caveats:
- [Limitations & Constraints](docs/deployment_models/limitations.md)

Each guide covers:
- Recommended instance sizes & limits
- Optional swap and resource tuning
- Building & pushing the workspace image
- Terraform variable usage (`enable_jetbrains_gateway`, `workspace_image`, resource limits)
- Upgrade and hardening paths

If you plan to contribute another provider (e.g., DigitalOcean, Hetzner), follow the same structure under `docs/deployment_models/` and link it here.
