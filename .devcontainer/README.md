# Coder Templates Development Container

This devcontainer is optimized for developing and managing Coder templates with Terraform, Docker, and cloud provider CLIs.

## Features

- **Terraform**: Infrastructure as code for Coder workspace definitions
- **Docker CLI**: Build and test workspace images locally
- **gcloud CLI**: Deploy and manage GCP Compute Engine workspaces
- **GitHub CLI**: Manage repositories and releases
- **Git LFS**: Handle large binary files efficiently
- **Rust (optional)**: For using terminal-jarvis as a consumer tool
- **VS Code Extensions**: Terraform, Docker, YAML, and GitHub Copilot

## Quick Start

After the container builds and initializes:

```bash
# Verify tooling
terraform version
docker --version
gcloud version
gh --version

# Format and validate Terraform
cd terminal-jarvis-playground/local-docker
terraform fmt
terraform validate

# Build a workspace image (local-docker)
docker build -t coder-terminal-jarvis-playground:latest .

# Package templates for upload to Coder
cd terminal-jarvis-playground/local-docker
tar -cf ../../terminal-jarvis-playground-local.tar .

cd ../gcp
tar -cf ../terminal-jarvis-playground-gcp.tar .
```

## Development Workflow

### Creating New Templates

```bash
# 1. Create provider directory
mkdir -p terminal-jarvis-playground/aws

# 2. Create Terraform config (main.tf)
# 3. Create Dockerfile
# 4. Create README.md with setup instructions

# 5. Format Terraform
terraform fmt terminal-jarvis-playground/aws/

# 6. Validate configuration
cd terminal-jarvis-playground/aws
terraform init
terraform validate
```

### Testing Templates Locally

```bash
# Build Docker image
cd terminal-jarvis-playground/local-docker
docker build -t coder-terminal-jarvis-playground:latest .

# Test the image
docker run -it --rm coder-terminal-jarvis-playground:latest bash

# Verify tools are installed
docker run -it --rm coder-terminal-jarvis-playground:latest bash -c "rustc --version && node --version"
```

### Packaging Templates

```bash
# Package local-docker template
cd terminal-jarvis-playground/local-docker
tar -cf ../../terminal-jarvis-playground-local.tar .

# Package GCP template
cd terminal-jarvis-playground/gcp
tar -cf ../terminal-jarvis-playground-gcp.tar .

# Upload .tar files to Coder dashboard
```

## Cloud Provider Setup

### GCP Authentication

```bash
# Authenticate with your GCP account
gcloud auth login

# Set default project
gcloud config set project YOUR_PROJECT_ID

# Create service account for Coder
gcloud iam service-accounts create coder-sa --display-name="Coder Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:coder-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:coder-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### GitHub Authentication

```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

## Using Terminal-Jarvis (Consumer)

This repository uses terminal-jarvis as a consumer tool for AI-assisted development:

```bash
# Install terminal-jarvis (if Rust is available)
cargo install terminal-jarvis

# Use terminal-jarvis for AI assistance
terminal-jarvis list
terminal-jarvis run claude "Help me write Terraform for AWS"
```

## Environment Variables

- `DOCKER_BUILDKIT=1` - Enable Docker BuildKit for faster builds

## Tips

- Use Docker-in-Docker for building workspace images without leaving the devcontainer
- Keep Terraform files formatted with `terraform fmt -recursive`
- Test templates locally before uploading to Coder
- Document cloud provider setup in each template's README.md
- Use GitHub Copilot for Terraform and Dockerfile assistance

## Troubleshooting

### Docker Socket Issues

If Docker commands fail:
```bash
# Check Docker socket is mounted
ls -l /var/run/docker.sock

# Test Docker connection
docker ps
```

### Terraform Validation Errors

```bash
# Initialize Terraform
cd terminal-jarvis-playground/<provider>
terraform init

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check
```

### Cloud Provider Authentication

```bash
# Verify gcloud authentication
gcloud auth list

# Verify GitHub authentication
gh auth status
```

## Structure

```
coder-templates/
├── terminal-jarvis-playground/
│   ├── local-docker/
│   │   ├── Dockerfile
│   │   ├── main.tf
│   │   └── README.md
│   └── gcp/
│       ├── Dockerfile
│       ├── main.tf
│       └── README.md
├── docs/
│   ├── coder_templates/
│   └── deployment_models/
└── .devcontainer/
    ├── Dockerfile
    ├── devcontainer.json
    ├── README.md (this file)
    └── scripts/
        └── setup-dev-environment.sh
```
