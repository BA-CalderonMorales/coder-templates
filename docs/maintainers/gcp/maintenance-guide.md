# GCP Template Maintenance Guide

This guide provides essential commands and procedures for maintaining and troubleshooting the Terminal Jarvis GCP Coder template.

## Quick Reference

### Check VM Status

```bash
# List all Coder workspace VMs in your project
gcloud compute instances list \
  --filter="labels.coder_workspace_id:*" \
  --project=YOUR_PROJECT_ID

# Get specific workspace VM details
gcloud compute instances describe INSTANCE_NAME \
  --zone=ZONE \
  --project=PROJECT_ID
```

### SSH into Workspace VM

```bash
# Via gcloud (requires gcloud auth)
gcloud compute ssh INSTANCE_NAME \
  --zone=ZONE \
  --project=PROJECT_ID

# Via Coder CLI (recommended)
coder ssh WORKSPACE_NAME
```

### Check Coder Agent Status

Once SSH'd into the VM:

```bash
# Check if Coder agent service is running
sudo systemctl status coder-agent

# View agent service logs (last 100 lines)
sudo journalctl -u coder-agent --no-pager -n 100

# Follow agent logs in real-time
sudo journalctl -u coder-agent -f

# Check if agent process is running
ps aux | grep coder
```

### Startup Script Logs

The VM startup script runs before the Coder agent starts:

```bash
# View startup script logs
sudo journalctl -u google-startup-scripts.service --no-pager

# Last 50 lines of startup logs
sudo journalctl -u google-startup-scripts.service --no-pager -n 50

# Follow startup script execution
sudo journalctl -u google-startup-scripts.service -f
```

### Check Agent Connectivity

```bash
# Test if agent can reach Coder server (from inside VM)
curl -I https://YOUR_CODER_URL/api/v2/buildinfo

# Verify agent token is set
sudo systemctl show coder-agent | grep CODER_AGENT_TOKEN

# Check network connectivity
ping -c 3 8.8.8.8
```

### Tool Installation Verification

```bash
# Check installed versions
node --version
rustc --version
python3 --version
uv --version
code-server --version
docker --version  # If Docker enabled

# Check if tools are in PATH
which node rust python3 cargo git gh

# Verify Rust environment
source ~/.cargo/env
cargo --version
```

## Common Issues and Solutions

### Agent Not Connecting

**Symptoms:** Workspace shows "Connecting..." indefinitely

**Diagnosis:**
```bash
# 1. SSH into VM
gcloud compute ssh INSTANCE_NAME --zone=ZONE --project=PROJECT_ID

# 2. Check agent service status
sudo systemctl status coder-agent

# 3. View recent agent logs for errors
sudo journalctl -u coder-agent --no-pager -n 100 | grep -i error
```

**Common Causes:**
- Agent token expired or invalid
- Network connectivity issues
- Startup script still installing dependencies
- Agent binary download failed

**Solutions:**
```bash
# Restart agent service
sudo systemctl restart coder-agent

# Verify coder user exists
id coder

# Check agent init script exists
ls -lh /opt/coder-agent-init.sh

# Manually run agent init script as coder user (for debugging)
sudo -u coder /opt/coder-agent-init.sh
```

### Startup Script Failed

**Symptoms:** VM starts but agent never connects

**Diagnosis:**
```bash
# Check for errors in startup script
sudo journalctl -u google-startup-scripts.service | grep -i error

# View full startup script output
sudo journalctl -u google-startup-scripts.service --no-pager
```

**Common Causes:**
- APT lock conflicts (cloud-init still running)
- Network timeout downloading tools
- Insufficient disk space

**Solutions:**
```bash
# Wait for cloud-init to complete
cloud-init status --wait

# Check disk space
df -h

# Manually install missing dependencies
sudo apt-get update
sudo apt-get install -y curl ca-certificates sudo
```

### Code-Server Not Appearing

**Symptoms:** Workspace connects but code-server app doesn't show up

**Diagnosis:**
```bash
# Check if code-server is installed
which code-server

# Check if code-server is running
ps aux | grep code-server

# View agent logs for app health checks
sudo journalctl -u coder-agent | grep -i "code-server\|apphealth"
```

**Solutions:**
```bash
# Wait 2-3 minutes after first connection (tools still installing)
# Check tools installation flag
ls -lh ~/.tools_installed

# Manually install code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.96.2

# Restart agent to trigger app detection
sudo systemctl restart coder-agent
```

### Docker Not Starting (When Enabled)

**Symptoms:** `enable_docker = true` but Docker commands fail

**Diagnosis:**
```bash
# Check Docker service status
sudo systemctl status docker

# Verify coder user is in docker group
groups coder | grep docker

# Test Docker daemon
sudo docker ps
```

**Solutions:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add coder user to docker group
sudo usermod -aG docker coder

# Log out and back in (or restart agent)
sudo systemctl restart coder-agent
```

### Archestra Container Not Running

**Symptoms:** `enable_archestra = true` but Archestra apps don't appear

**Diagnosis:**
```bash
# Check if container is running
docker ps | grep archestra

# View container logs
docker logs archestra-platform

# Check if ports are bound
sudo netstat -tulpn | grep -E ':(3000|9000)'
```

**Solutions:**
```bash
# Pull and start Archestra container manually
docker pull archestra/platform:latest
docker run -d \
  --name archestra-platform \
  --restart unless-stopped \
  -p 3000:3000 \
  -p 9000:9000 \
  archestra/platform:latest

# Check container status
docker ps -a | grep archestra
```

### Rust Environment Not Loaded

**Symptoms:** `rustc: command not found` even though Rust is installed

**Diagnosis:**
```bash
# Check if Rust is installed
ls -la ~/.cargo/bin/

# Check if cargo env file exists
ls -lh ~/.cargo/env
```

**Solutions:**
```bash
# Load Rust environment in current shell
source ~/.cargo/env

# Add to shell profile for persistence
echo 'source $HOME/.cargo/env' >> ~/.bashrc
```

## VM Lifecycle Management

### Stop Workspace (Saves Costs)

```bash
# Via Coder CLI
coder stop WORKSPACE_NAME

# Via Coder UI
# Navigate to workspace → Click "Stop"

# Verify VM is stopped
gcloud compute instances list --filter="name:coder-*" --project=PROJECT_ID
```

### Start Workspace

```bash
# Via Coder CLI
coder start WORKSPACE_NAME

# Via Coder UI
# Navigate to workspace → Click "Start"
```

### Delete Workspace

```bash
# Via Coder CLI (deletes VM and disk)
coder delete WORKSPACE_NAME

# Verify cleanup
gcloud compute instances list --filter="name:coder-*" --project=PROJECT_ID
gcloud compute disks list --filter="name:coder-*" --project=PROJECT_ID
```

## Monitoring and Observability

### Resource Usage

From inside the VM:

```bash
# CPU and memory usage
htop

# Disk usage
df -h
du -sh ~/*

# Network connections
sudo netstat -tulpn

# Check Coder agent metrics (available in Coder dashboard)
coder stat cpu
coder stat mem
coder stat disk --path $HOME
```

### Log Collection for Support

```bash
# Collect all relevant logs
sudo journalctl -u coder-agent --no-pager > coder-agent.log
sudo journalctl -u google-startup-scripts.service --no-pager > startup-script.log
docker logs archestra-platform > archestra.log 2>&1  # If Archestra enabled

# System info
uname -a > system-info.txt
df -h >> system-info.txt
free -h >> system-info.txt

# Package information
dpkg -l | grep -E 'node|rust|python|docker' > installed-packages.txt
```

## Disk Persistence

### What Persists

The entire root filesystem persists across workspace restarts, including:
- `/home/coder` (user home directory)
- All installed tools (Rust, Node.js, Python, Docker images)
- Git repositories and workspace files
- Configuration files (~/.gitconfig, ~/.bashrc, etc.)

### What's Ephemeral

- VM compute instance (deleted on stop, recreated on start)
- Ephemeral public IP address
- Running processes (including Docker containers)

### Disk Management

```bash
# Check persistent disk details
gcloud compute disks describe DISK_NAME \
  --zone=ZONE \
  --project=PROJECT_ID

# Check disk size
df -h /

# Clean up space if needed
docker system prune -a  # Remove unused Docker data
cargo clean  # Clean Rust build artifacts
npm cache clean --force
```

## Template Updates

### Applying Template Changes

1. Update `main.tf` or `README.md` in the repository
2. Package the template:
   ```bash
   cd terminal-jarvis-playground/gcp
   tar -cf ../terminal-jarvis-playground-gcp.tar .
   ```
3. Upload to Coder as a new template version
4. Existing workspaces continue using old template version
5. New workspaces use the latest template version

### Updating Existing Workspace

To apply template changes to an existing workspace:

```bash
# Option 1: Via Coder CLI
coder update WORKSPACE_NAME

# Option 2: Via Coder UI
# Navigate to workspace → Settings → Update
```

**Warning:** Template updates may require workspace rebuild, which recreates the VM (but disk persists).

## Security Considerations

### Service Account Permissions

The template requires these GCP IAM roles:
- Compute Admin
- Service Account User

Verify permissions:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:SERVICE_ACCOUNT_EMAIL"
```

### Firewall Rules

The template creates a firewall rule allowing SSH (port 22) from anywhere:

```bash
# List Coder-related firewall rules
gcloud compute firewall-rules list \
  --filter="name:coder-*" \
  --project=PROJECT_ID

# View specific rule
gcloud compute firewall-rules describe RULE_NAME --project=PROJECT_ID
```

### Credentials Management

- GCP credentials are stored securely in Coder (marked as sensitive)
- Never commit service account JSON keys to git
- Rotate service account keys regularly

## Performance Optimization

### e2-micro vs e2-medium

**e2-micro (1 GB RAM):**
- Free tier eligible
- Slower tool installation (10-15 minutes)
- May struggle with heavy builds
- Sufficient for light development

**e2-medium (4 GB RAM):**
- Faster tool installation (3-5 minutes)
- Better for Rust compilation
- Recommended for active development
- ~$24/month if running 24/7

### Startup Time Optimization

The startup script installs tools progressively:

1. Minimal dependencies (curl, ca-certificates) - 30 seconds
2. Coder agent starts and connects - 1 minute
3. Full tooling (Rust, Node.js, Python) - 10-15 minutes (e2-micro)

To speed up subsequent starts:
- Tools are cached after first installation (~/.tools_installed flag)
- Subsequent starts only take 1-2 minutes

## Backup and Recovery

### Manual Snapshot

```bash
# Create snapshot of persistent disk
gcloud compute disks snapshot DISK_NAME \
  --snapshot-names=WORKSPACE_NAME-backup-$(date +%Y%m%d) \
  --zone=ZONE \
  --project=PROJECT_ID

# List snapshots
gcloud compute snapshots list --filter="name:WORKSPACE_NAME-*"
```

### Restore from Snapshot

```bash
# Create new disk from snapshot
gcloud compute disks create DISK_NAME-restored \
  --source-snapshot=SNAPSHOT_NAME \
  --zone=ZONE \
  --project=PROJECT_ID
```

## Troubleshooting Checklist

When a workspace isn't working:

- [ ] VM is running: `gcloud compute instances list`
- [ ] SSH access works: `gcloud compute ssh INSTANCE_NAME`
- [ ] Startup script completed: `sudo journalctl -u google-startup-scripts.service | tail`
- [ ] Coder agent running: `sudo systemctl status coder-agent`
- [ ] Agent can reach Coder server: `curl -I https://YOUR_CODER_URL`
- [ ] Tools installed: `which node rust python3`
- [ ] Disk space available: `df -h`
- [ ] No errors in logs: `sudo journalctl -u coder-agent | grep -i error`

## Support Resources

- Coder Documentation: https://coder.com/docs
- GCP Compute Engine Docs: https://cloud.google.com/compute/docs
- Template Repository: https://github.com/BA-CalderonMorales/coder-templates
- Stable Baseline Tag: `stable-gcp-bare-vm-v1.0`
