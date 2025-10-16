# GCP Coder Template Troubleshooting

## Problem Statement

Workspace creation succeeds (GCP VM is created and running), but the Coder agent never connects back to the Coder server, resulting in:
- "Workspace is unhealthy" error
- No build timeline logs visible in Coder UI
- VS Code, Terminal, and other apps are inaccessible

## Verification Commands

### Check if VM exists and is running
```bash
gcloud compute instances list --project=terminal-jarvis-playground
```

### SSH into the VM to debug
```bash
gcloud compute ssh coder-ba-calderonmorales-tj-playground-try-2 \
  --zone=us-central1-a \
  --project=terminal-jarvis-playground
```

### Once inside VM, check logs
```bash
# Check startup script logs
sudo journalctl -u google-startup-scripts.service --no-pager | tail -100

# Check if Docker is installed
docker --version

# Check running containers
docker ps -a

# Check Docker logs if container exists
docker logs <container-name>

# Check if coder user exists
id coder

# Check system logs
sudo tail -50 /var/log/syslog
```

## Approaches Tried (FAILED)

### Attempt 1: Run Coder agent directly on bare VM
**Date**: 2025-10-15
**File**: main.tf lines 233-252 (original)
**Approach**: Used `metadata_startup_script` to run `coder_agent.main.init_script` directly on the Ubuntu VM
**Error**: `CODER_AGENT_TOKEN or CODER_AGENT_TOKEN_FILE must be set for token auth`
**Root Cause**: The init script wasn't properly expanding Terraform variables when wrapped in heredoc
**Status**: FAILED - Wrong architectural approach

### Attempt 2: Fix heredoc variable expansion
**Date**: 2025-10-15
**File**: main.tf lines 249-251
**Change**: Removed single quotes from heredoc delimiter (`<<AGENT_SCRIPT` instead of `<<'AGENT_SCRIPT'`)
**Rationale**: Allow Terraform to expand `${coder_agent.main.init_script}` variable
**Status**: FAILED - Still hung, agent never connected

### Attempt 3: Docker-in-VM architecture
**Date**: 2025-10-15
**File**: main.tf.backup-docker-approach
**Approach**:
- Install Docker on the GCP VM via startup script
- Run workspace as a Docker container on the VM
- Pass `CODER_AGENT_TOKEN` as environment variable to container
**Changes Made**:
- Modified agent startup_script to remove code-server installation
- Replaced manual `coder_app` with `code-server` module (registry.coder.com/modules/code-server/coder)
- Rewrote `metadata_startup_script` to install Docker and run container
**Status**: FAILED - Still hanging during workspace creation
**Root Cause**: Using fallback ubuntu:22.04 image without dependencies needed by init_script

### Attempt 4: Bare VM without Docker (CURRENT)
**Date**: 2025-10-16
**File**: main.tf lines 228-290
**Approach**:
- Remove Docker entirely
- Install dependencies directly on VM (curl, git, Node.js, build tools)
- Create coder user with sudo access
- Run Coder agent as systemd service
- Agent runs directly on VM as coder user
**Changes Made**:
- Rewrote `metadata_startup_script` to install dependencies via apt
- Added cloud-init wait to avoid apt lock conflicts
- Created systemd service unit for agent with auto-restart
- Added comprehensive logging (syslog + journalctl)
- Installed Node.js 20.x to match local Docker template
- Agent startup_script installs code-server on first run
**Benefits**:
- No Docker complexity or networking issues
- Easy debugging via `journalctl -u coder-agent`
- Direct SSH access to see agent logs in real-time
- Matches most official Coder GCP examples
- All dependencies explicitly installed and verified
**Status**: TESTING

## Current Architecture Issues

### Issue 1: Image availability
Line 243-246 uses `ubuntu:22.04` as fallback, but the actual Dockerfile (with code-server, Rust, Node.js, etc.) is never built or pulled. The workspace container is running a minimal Ubuntu image without any dev tools.

### Issue 2: Init script execution
The `coder_agent.main.init_script` contains the agent binary download and execution logic, but it may not be running correctly inside the container due to:
- Missing dependencies in the fallback ubuntu:22.04 image
- Network connectivity issues between container and Coder server
- Incorrect entrypoint/command structure

### Issue 3: Docker networking
The container may not be able to reach the Coder server at `https://2dvhb92th5644.pit-1.try.coder.app/` due to:
- No explicit network configuration
- Firewall rules only allow SSH (port 22), not agent connections
- Container may need `--network host` mode

### Issue 4: Logs are invisible
Cannot see Terraform apply logs or build timeline in Coder UI, making debugging extremely difficult. This suggests:
- Terraform provider authentication issues
- Coder server not receiving status updates from provisioner
- Template may not be properly uploaded/versioned

## Architecture Comparison

### Local Docker Template (WORKING)
```
Coder Server (local)
  └─> Docker Provider (local Docker socket)
      └─> Docker Container
          └─> Coder Agent (inside container)
              └─> code-server module
```

### GCP Template (NOT WORKING)
```
Coder Server (pit-1.try.coder.app)
  └─> Google Provider
      └─> GCP Compute Instance (VM)
          └─> Docker Engine (installed via startup script)
              └─> Docker Container (???)
                  └─> Coder Agent (not connecting)
                      └─> code-server module
```

## Next Steps to Try

### Option A: Use google_compute_instance with Docker provider (RECOMMENDED)
Instead of installing Docker via startup script, use Terraform's Docker provider with a remote Docker host:
1. VM startup script: Install Docker and expose TCP socket with TLS
2. Add Docker provider pointing to VM's IP
3. Use docker_container resource (like local template) instead of running docker via shell script
4. This matches the working local architecture more closely

### Option B: Simplify to bare VM without Docker
Remove Docker entirely and run agent directly on VM:
1. Ensure code-server is installed on the VM (via startup script or pre-baked image)
2. Fix the init script execution to properly pass token
3. Simpler architecture but loses container isolation

### Option C: Use official Coder GCP examples
Reference: https://github.com/coder/coder/tree/main/examples/templates/gcp-linux
Check if Coder has official GCP templates that work and compare architecture

### Option D: Debug with minimal template
Create a minimal test template:
1. Single GCP VM
2. Single agent resource
3. No modules, no Docker, just agent connection
4. Use this to verify basic connectivity first

## Known Working Examples

### Coder Cloud + GCP VM Pattern
The logs show the Coder server is at `https://2dvhb92th5644.pit-1.try.coder.app/` (Coder's managed service). The agent successfully downloads from this URL but fails to authenticate.

Check Coder's official docs for GCP cloud deployment patterns:
- https://coder.com/docs/templates
- https://github.com/coder/coder/tree/main/examples/templates

## Security Notes

### Do NOT commit:
- GCP service account JSON keys (`gcp_credentials` variable should be passed at workspace creation time)
- Coder agent tokens (these are ephemeral and generated per workspace)
- Any credentials, API keys, or secrets

### Safe to commit:
- This troubleshooting doc
- Template code (main.tf, Dockerfile, README)
- Non-sensitive configuration variables

### Firewall Configuration
Current firewall rule (line 172-183) only allows SSH. The Coder agent needs OUTBOUND connectivity to the Coder server, which GCP allows by default. However, if running Coder server on the VM itself, you'd need ingress rules.

## Environment Details

**Coder Server**: pit-1.try.coder.app (Coder Cloud)
**GCP Project**: terminal-jarvis-playground
**Zone**: us-central1-a
**Machine Type**: e2-micro
**Disk Size**: 16 GB
**VM Name Pattern**: coder-{owner}-{workspace}

## Questions to Answer

1. Is the Docker container actually starting on the VM?
2. Is the Coder agent binary downloading inside the container?
3. Can the container reach the Coder server URL?
4. Is the `CODER_AGENT_TOKEN` environment variable set correctly?
5. Does the code-server module work without Docker on a bare VM?

## Recommended Debugging Session (Attempt 4 - Bare VM)

```bash
# 1. SSH into VM
gcloud compute ssh coder-<owner>-<workspace> \
  --zone=us-central1-a \
  --project=terminal-jarvis-playground

# 2. Check startup script logs
sudo journalctl -u google-startup-scripts.service --no-pager | tail -100

# 3. Check Coder agent service status
sudo systemctl status coder-agent

# 4. View Coder agent logs in real-time
sudo journalctl -u coder-agent -f

# 5. Check if coder user exists
id coder

# 6. Check installed dependencies
node --version
git --version
code-server --version

# 7. Check if agent binary downloaded
sudo ls -lh /tmp/coder* 2>/dev/null || echo "No agent binary found"

# 8. Test network connectivity to Coder server (extract URL from service file)
CODER_URL=$(grep -oP 'https://[^/]+\.coder\.app' /etc/systemd/system/coder-agent.service || echo "URL not found")
echo "Coder server URL: $CODER_URL"
curl -I "$CODER_URL/"

# 9. If agent service failed, try manual start for debugging
sudo su - coder
# Token is in the systemd service file, extract it:
# grep CODER_AGENT_TOKEN /etc/systemd/system/coder-agent.service
export CODER_AGENT_TOKEN="<token-from-service-file>"
# Paste the init_script commands manually to see detailed output
```

## Last Updated

2025-10-16 - Attempt 4: Bare VM approach implemented

## References

- Local working template: `/workspaces/coder-templates/terminal-jarvis-playground/local-docker/main.tf`
- GCP deployment guide: `/workspaces/coder-templates/docs/deployment_models/GCP.md`
- Coder agent documentation: https://coder.com/docs/coder/latest/agents
