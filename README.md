# Coder Templates

This repository contains templates and utilities for creating consistent development environments using Coder.

## Purpose

The `start.windows.sh` script packages the Terminal-Jarvis development environment template into a portable tar archive (`.tar`). This is a crucial step in the Coder template workflow:

1. Define the development environment in the `terminal-jarvis-playground` directory
2. Run `start.windows.sh` to create `terminal-jarvis-playground.tar`
3. Upload the generated `.tar` file to Coder as a new template
4. Coder uses this template to create consistent development environments for all team members

This workflow ensures that every developer gets the same environment with all necessary tools (Node.js, Git, etc.) pre-configured.

### Current Template

- `terminal-jarvis-playground`: A development environment for Terminal-Jarvis with Node.js and Git support.

### Usage

To package the template environment, use the appropriate script for your operating system:

```bash
# For Windows
./start.windows.sh

# For macOS
./start.mac.sh

# For Linux
./start.linux.sh
```

Any of these scripts will create:
- `terminal-jarvis-playground.tar`: Contains the basic Node.js development environment

### Template Structure

The template directory contains:
- `Dockerfile`: Defines the development environment
- `main.tf`: Terraform configuration for the Coder workspace
- Additional configuration files as needed

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
