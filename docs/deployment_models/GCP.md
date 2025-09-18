# GCP Deployment Model (Free-Tier Friendly)

This guide explains how to run the `terminal-jarvis-playground` Coder template on Google Cloud Platform using (mostly) always-free resources.

## Overview
GCP Always Free provides one `e2-micro` VM per eligible region (2 vCPU burstable, ~1 GiB RAM), 30 GB standard persistent disk, and limited egress.

Because JetBrains IDE backends are memory-intensive, this profile focuses on `code-server` only. You can optionally enable JetBrains later by upgrading the machine size (e.g. `e2-medium` or `n2-standard-2`).

## Architecture
- Single Compute Engine VM running:
  - Docker Engine
  - (Option A) Coder server + workspaces on same host
  - (Option B) Coder server elsewhere; VM only runs the Docker workspace container
- Persistent Disk stores Docker data + user home (via volume or bind mount)

## Sizing Choices
| Component | Value | Notes |
|-----------|-------|------|
| Machine Type | e2-micro | Always-free eligible |
| Boot Disk | 20–30 GB standard persistent disk | Keep under free quota |
| Memory Use | ~450–700 MB idle | code-server light usage |
| Swap (recommended) | 1 GB | Mitigates OOM during spikes |

## Prerequisites
- GCP project with billing enabled
- gcloud CLI installed locally
- (If self-hosting Coder elsewhere) Network route & firewall to Docker host

## Step 1: Create VM
```bash
gcloud compute instances create coder-dev \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=coder,ssh,https
```

Open firewall (only if not using a load balancer / Cloud Run proxy):
```bash
gcloud compute firewall-rules create allow-coder --allow=tcp:7080 --target-tags=coder
```

## Step 2: Install Docker
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Re-login or: exec su -l $USER
```

(Optional) Add swap:
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo sudo tee -a /etc/fstab
```

## Step 3A: Run Coder Server On Same Host
```bash
curl -fsSL https://coder.com/install.sh | sh
coder server --accept-tos &
```
Secure with a reverse proxy + TLS (Caddy, Nginx, Cloudflare Tunnel) for production.

## Step 3B: Remote Docker Host Mode
If Coder server runs elsewhere, expose secured Docker TCP with TLS and use Terraform variables `docker_host`, `docker_ca_cert`, etc.

## Step 4: Build Workspace Image
(From repo root cloned on the VM)
```bash
cd terminal-jarvis-playground
docker build -t coder-terminal-jarvis-playground:latest .
```

For faster cold starts, push to Artifact Registry (optional):
```bash
gcloud artifacts repositories create dev-images --repository-format=DOCKER --location=us-central1
PROJECT_ID=$(gcloud config get-value project)
gcloud auth configure-docker us-central1-docker.pkg.dev
docker tag coder-terminal-jarvis-playground:latest us-central1-docker.pkg.dev/$PROJECT_ID/dev-images/coder-terminal-jarvis-playground:latest
docker push us-central1-docker.pkg.dev/$PROJECT_ID/dev-images/coder-terminal-jarvis-playground:latest
```
Then set Terraform variable `workspace_image`.

## Step 5: Apply Terraform
If Terraform is run inside the VM with Coder provider authenticated:
```bash
cd terminal-jarvis-playground
terraform init
terraform apply -auto-approve \
  -var enable_jetbrains_gateway=false \
  -var memory_limit_mb=768
```

## Step 6: Access Environment
Access code-server through the Coder UI (port forwarded inside the product). If self-hosted bare, secure direct connections with HTTPS.

## Cost / Quota Watchlist
- Persistent Disk usage (stay <= 30 GB standard)
- Network egress (clone large repos cautiously)
- Snapshots (first 5 GB free)

## Upgrade Path
- Increase machine type to `e2-medium` for JetBrains
- Add additional persistent disk for larger home directories
- Use Cloud DNS + HTTPS termination

## Troubleshooting
| Issue | Symptom | Fix |
|-------|---------|-----|
| OOM Kill | Container exits building dependencies | Add swap / reduce extensions |
| Slow Start | Image pulls every restart | Pre-push to regional registry |
| High CPU Steal | Code server sluggish | Move to less contended zone or bigger instance |

---
Last updated: 2025-09-18
