# Docker Desktop (Local Baseline)

This guide covers running the `terminal-jarvis-playground` template locally using Docker Desktop (macOS, Windows, or Linux). This is the fastest iteration loop and the reference baseline for other cloud deployment models.

## Why Start Here?
- Zero cloud cost, no VM quota limits
- Simplest debugging of image + Terraform logic
- Rapid rebuilds using local layer cache

## Prerequisites
- Docker Desktop (or plain Docker Engine + Compose) installed
- (Optional) Coder server running locally (`coder server`)

## Quick Start (Local Only)
Clone repo and package template:
```bash
git clone <this-repo>
cd coder-templates
./start.mac.sh   # or ./start.linux.sh / start.windows.sh
```
This produces `terminal-jarvis-playground.tar` which you can upload in the Coder UI as a template.

## Direct Terraform Apply (Without Packaging)
You can also run Terraform directly (assuming Coder provider authentication):
```bash
cd terminal-jarvis-playground
terraform init
terraform apply -auto-approve
```
This will build (if image already built) and launch the workspace container referencing `coder-terminal-jarvis-playground:latest`.

## Building the Workspace Image Manually
```bash
cd terminal-jarvis-playground
docker build -t coder-terminal-jarvis-playground:latest .
```
Multi-arch (if you have buildx & want arm64 + amd64 manifest):
```bash
docker buildx create --use --name multi || docker buildx use multi
docker buildx build --platform linux/amd64,linux/arm64 -t coder-terminal-jarvis-playground:latest .
```
(Without `--push` this remains local only.)

## Using JetBrains Gateway Locally
Even on 8+ GiB host machines, remember the container itself may have limited memory. If you plan to enable JetBrains via Terraform variable (future feature), ensure Docker Desktop resource limits (Preferences → Resources) allocate at least 4 GiB.

## Bind Mount Alternative
Instead of a Docker-managed volume you can bind mount your local path for easier file inspection:
```hcl
volumes {
  container_path = "/home/coder"
  host_path      = "/ABSOLUTE/PATH/dev-home"
  read_only      = false
}
```
Useful for debugging persistent state.

## Troubleshooting
| Issue | Symptom | Fix |
|-------|---------|-----|
| file perms off | Git inside container shows root-owned files | Ensure Docker build doesn’t chown incorrectly; rebuild |
| slow rebuilds | Frequent cache misses | Reorder Dockerfile layers (dependencies before app) |
| code-server unresponsive | High local CPU | Disable heavy extensions; allocate more Docker Desktop CPUs |

## Next Step
Once stable locally, replicate steps in a cloud doc (GCP/AWS/Azure) adjusting for resource limits and adding swap if necessary.

---
Last updated: 2025-09-18
