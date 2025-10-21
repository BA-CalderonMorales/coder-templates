# Coder Templates

Terraform-based workspace templates for creating consistent, portable development environments on Coder.

## Overview

This repository provides production-ready Coder workspace templates designed for the Terminal-Jarvis development environment. Templates use Terraform to provision containerized workspaces with pre-configured toolchains including Node.js 20, Python 3, Rust, and development utilities. The templates target both local Docker deployments and cloud infrastructure, with an emphasis on free-tier and low-cost options.

## Project Status

**Implemented:**
- Local Docker template using Docker containers with persistent volumes
- GCP Compute Engine template using bare VM architecture
- Multi-platform packaging scripts (Linux, macOS, Windows)
- Comprehensive deployment documentation for GCP, AWS, and Azure
- Development container for contributors
- Resource monitoring and observability built into templates

**Planned:**
- Feature flags for optional components (JetBrains Gateway, resource limits)
- Multi-architecture image builds (AMD64 + ARM64) via GitHub Actions
- AWS and Azure template implementations (documentation exists, Terraform pending)
- Automated linting and validation pipeline (tflint, trivy/grype)
- Secret management patterns (dotfiles, cloud secret managers)

See `CLAUDE.md` for detailed roadmap and development guidelines.

## Architecture

### Template Model

Each template consists of three core components:

1. **Dockerfile** - Defines the workspace runtime environment with pre-installed tools
2. **main.tf** - Terraform configuration declaring Coder resources and infrastructure
3. **README.md** - Deployment-specific setup and configuration instructions

Templates are packaged into `.tar` archives and uploaded to Coder for workspace provisioning.

### Persistence Strategy

- **Ephemeral:** Workspace container or VM (recreated on restart)
- **Persistent:** User data in `/home/coder` via Docker volumes or attached disks
- **Consequence:** Tools installed outside persistent paths must be baked into Dockerfile

### Provider Architecture

**local-docker:**
- Providers: `coder/coder`, `kreuzwerker/docker`
- Resources: Docker container with persistent volume
- Modules: code-server (VS Code in browser), JetBrains Gateway
- Base Image: `codercom/enterprise-base:ubuntu`

**gcp:**
- Providers: `coder/coder`, `google`
- Resources: Compute Engine VM with persistent root disk
- Modules: code-server, optional Archestra.ai integration
- Base Image: `ubuntu:22.04` with code-server pre-installed
- Architecture: Bare VM with systemd-managed Coder agent

### Observability

Templates include real-time dashboard metrics:
- CPU usage (container/host)
- RAM usage with percentage utilization
- Disk usage for home directory
- Load average scaled by CPU count
- Swap usage (critical for memory-constrained instances)

See `main.tf:89-148` in local-docker template for implementation details.

## Quick Start

### 1. Package Template

Run the packaging script for your platform:

```bash
# Interactive mode - presents menu of templates
./package.linux.sh     # Linux
./package.mac.sh       # macOS
./package.windows.sh   # Windows (Git Bash/WSL)

# Direct mode - package specific template
./package.linux.sh local-docker   # Creates terminal-jarvis-playground-local.tar
./package.linux.sh gcp            # Creates terminal-jarvis-playground-gcp.tar
./package.linux.sh all            # Creates both archives
```

### 2. Upload to Coder

1. Navigate to Coder dashboard
2. Go to Templates → Create Template
3. Upload generated `.tar` file
4. Configure template variables (see template README)
5. Create workspace from template

### 3. Template-Specific Setup

Consult the README in each template directory for deployment-specific requirements:
- `terminal-jarvis-playground/local-docker/README.md` - Docker Desktop setup
- `terminal-jarvis-playground/gcp/README.md` - GCP credentials and project configuration

## Available Templates

### terminal-jarvis-playground/local-docker

Docker-based workspace for local development and testing.

**Requirements:**
- Docker Desktop or Docker Engine
- 2+ GiB RAM recommended (JetBrains IDEs require 4+ GiB)

**Features:**
- Persistent `/home/coder` volume
- code-server for browser-based VS Code
- JetBrains Gateway support (IntelliJ, PyCharm, WebStorm, etc.)
- Automatic git configuration from Coder user metadata

**Terraform Variables:**
- `docker_socket` (optional) - Custom Docker socket path

See: `terminal-jarvis-playground/local-docker/README.md`

### terminal-jarvis-playground/gcp

Google Compute Engine deployment using ephemeral VMs with persistent disks.

**Requirements:**
- GCP project with Compute Engine API enabled
- Service account with `compute.instanceAdmin.v1` role
- Service account JSON key file

**Features:**
- Bare VM architecture (no Docker dependency)
- Always Free tier eligible (e2-micro, 30 GB disk)
- Systemd-managed Coder agent with auto-restart
- Optional Archestra.ai integration
- Optional Docker installation for container workflows

**Terraform Variables:**
- `project_id` (required) - GCP project ID
- `zone` (optional) - Compute zone, default: `us-central1-a`
- `machine_type` (optional) - Instance size, default: `e2-micro`
- `disk_size` (optional) - Root disk GB, default: `30`
- `gcp_credentials` (sensitive) - Service account JSON key
- `enable_archestra` (optional) - Enable Archestra.ai, default: `false`
- `enable_docker` (optional) - Install Docker, default: `false`

See: `terminal-jarvis-playground/gcp/README.md`

## Deployment Options

Detailed deployment guides are available for multiple platforms:

| Platform | Status | Guide | Free Tier Details |
|----------|--------|-------|-------------------|
| Docker Desktop | Implemented | `docs/deployment_models/DockerDesktop.md` | Local baseline |
| Google Cloud Platform | Implemented | `docs/deployment_models/GCP.md` | e2-micro, 30 GB disk (Always Free) |
| Amazon Web Services | Documented | `docs/deployment_models/AWS.md` | t2.micro (12-month free tier) |
| Microsoft Azure | Documented | `docs/deployment_models/Azure.md` | B1s (limited free tier) |

**Note:** AWS and Azure guides document deployment approaches, but Terraform templates are not yet implemented. Contributions welcome.

See `docs/deployment_models/limitations.md` for comprehensive resource constraints and platform-specific caveats.

## Resource Requirements and Limitations

### Critical Constraints

**Memory:**
- 1 GiB RAM instances (GCP e2-micro, AWS t2.micro/t4g.micro, Azure B1s) cannot reliably run JetBrains IDE backends
- Minimum 2 GiB RAM recommended for code-server only
- Minimum 4 GiB RAM recommended for JetBrains Gateway
- 1 GiB swap recommended for memory-constrained instances

**CPU:**
- Azure B1s enforces CPU credit limits that can throttle sustained workloads
- AWS t2/t4g instances have similar burstable CPU constraints
- GCP e2-micro provides 2 vCPUs with 0.25-1.0 vCPU sustained usage

**Disk:**
- GCP Always Free: 30 GB standard persistent disk
- AWS Free Tier: 30 GB EBS storage
- Azure Free: 64 GB disk (B1s)
- Target workspace image size: < 1.2 GB compressed

**Architecture:**
- ARM64 support critical for AWS t4g instances and Apple Silicon
- Use `docker buildx --platform linux/amd64,linux/arm64` for multi-arch images

See `docs/deployment_models/limitations.md` for detailed analysis and mitigation strategies.

## Template Structure

Each template directory contains:

```
terminal-jarvis-playground/{template-name}/
├── Dockerfile          # Workspace runtime environment
├── main.tf             # Terraform configuration
└── README.md           # Deployment-specific instructions
```

### Dockerfile

Defines the workspace image with pre-installed development tools:
- Ubuntu base (22.04 or Coder enterprise base)
- Node.js 20 (via nvm)
- Python 3 with uv package manager
- Rust 1.87.0 toolchain
- Git, GitHub CLI, and common utilities
- Platform-specific additions (code-server for GCP)

### main.tf

Terraform configuration declaring:
- Required providers (Coder + infrastructure provider)
- Template variables with defaults and validation
- Coder agent with startup scripts and environment
- Infrastructure resources (containers, VMs, volumes, disks)
- Coder modules (code-server, JetBrains Gateway)
- Monitoring metadata (CPU, RAM, disk, load, swap)

### README.md

Deployment guide covering:
- Prerequisites and setup requirements
- Building and publishing workspace images
- Configuring Terraform variables
- Creating and managing workspaces
- Troubleshooting common issues

## Development

### Prerequisites

- Docker Desktop or Docker Engine
- Terraform 1.0+
- Git

### Local Testing

Use the development container for consistent contributor environments:

```bash
# Open in VS Code with Remote Containers extension
code .devcontainer

# Or manually build and run
docker build -t coder-templates-dev .devcontainer/
docker run -it -v $(pwd):/workspace coder-templates-dev
```

See `.devcontainer/README.md` for full setup instructions.

### Validation Workflow

```bash
# Validate Terraform configuration
cd terminal-jarvis-playground/{template-name}
terraform init
terraform validate
terraform fmt -check

# Build Docker image
docker build -t test-image:latest .

# Package template
cd ../..
./package.linux.sh {template-name}
```

### Code Style

Refer to `.github/copilot-instructions.md` and `CLAUDE.md` for style guidelines:
- No emojis in code, documentation, or commit messages
- High-signal comments only
- Semantic section headers in documentation
- Sensible defaults that work without flags
- Small, composable Terraform changes

## Documentation Tools

### terraform-docs

Recommended for auto-generating module documentation from Terraform files.

**Installation:**

```bash
# macOS
brew install terraform-docs

# Linux
curl -Lo terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-linux-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/
```

**Usage:**

```bash
# Generate markdown documentation
cd terminal-jarvis-playground/local-docker
terraform-docs markdown table . > TERRAFORM.md

# Update README with embedded docs
terraform-docs markdown table . --output-file README.md --output-mode inject
```

**Integration:**

Consider adding to `.git/hooks/pre-commit` to auto-update documentation on commit. See `docs/maintainers/gcp/maintenance-guide.md` for automation examples.

### Additional Tools

- **tflint** - Terraform linter for catching errors and enforcing best practices
- **trivy** or **grype** - Container image vulnerability scanning
- **hadolint** - Dockerfile linting

These tools are planned for CI/CD integration but not yet implemented. Contributions welcome.

## Contributing

Contributions are welcome for:
- AWS and Azure template implementations
- Multi-architecture image builds
- Feature flag implementation (JetBrains Gateway, resource limits)
- Additional cloud provider templates (DigitalOcean, Hetzner, Linode)
- Documentation improvements
- CI/CD automation

Follow the structure established in existing templates and maintain consistency with style guidelines in `CLAUDE.md`.

## Maintenance

For maintainers managing deployed templates:
- `docs/maintainers/gcp/maintenance-guide.md` - GCP-specific operational procedures

## License

See `LICENSE` file for details.
