# AGENTS.md - Coder Templates

## Quick Reference

- **Purpose**: Coder workspace templates for Docker-based dev environments
- **Package**: `./package.linux.sh` (or `.mac.sh`, `.windows.sh`)
- **Template**: `terminal-jarvis-playground/`

## Core Commands

```bash
# Package template
./package.linux.sh    # Creates .tar for Coder upload

# Docker build
docker build -t coder-terminal-jarvis-playground:latest terminal-jarvis-playground/

# Multi-arch build
docker buildx build --platform linux/amd64,linux/arm64 -t coder-terminal-jarvis-playground:latest terminal-jarvis-playground/

# Terraform validation
cd terminal-jarvis-playground && terraform validate && terraform fmt
```

## Template Structure

- **Dockerfile**: Ubuntu base + Node.js 20 + Git
- **main.tf**: Coder agent + code-server + JetBrains Gateway modules
- **Persistence**: Docker volume at `/home/coder`

## Deployment Models

- Docker Desktop (local baseline)
- GCP e2-micro (Always Free)
- AWS t2.micro/t4g.micro (12-month free)
- Azure B1s (constrained CPU)

## Critical Constraints

- 1 GiB RAM instances cannot reliably run JetBrains IDE backends
- Target: < 1.2 GB compressed image
- ARM64 support critical for t4g instances

## Code Style

- **NO EMOJIS**: Prohibited in code, docs, commits, PRs
- Terraform: Small, composable changes
- Documentation: High-signal comments only
- Defaults: New features work without additional flags

## Working Rules

- Stop and explain before major architectural changes
- One change per commit, commit before starting next
- Do not bundle unrelated work into the same commit
