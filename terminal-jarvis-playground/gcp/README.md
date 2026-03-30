# Terminal-Jarvis GCP Template

A Coder template for running Terminal-Jarvis development environments on Google Compute Engine with persistent storage, comprehensive development tooling, and optional Archestra.ai integration.

## Architecture

This template provisions:

- **GCP Compute Instance** (ephemeral) - Stopped when workspace is stopped
- **GCP Persistent Disk** (persistent) - Root filesystem that persists across restarts
- **Coder Agent** - Runs as systemd service directly on the VM
- **Code-Server** - VS Code accessible through browser
- **Terminal Jarvis Tooling**:
  - Rust 1.87+ (rustc, cargo, clippy, rustfmt)
  - Node.js 20
  - Python 3 with pip, venv, and uv package manager
  - Git with Git LFS
  - GitHub CLI (gh)
  - Build tools (build-essential, pkg-config, libssl-dev)
- **Optional Docker** - For Archestra or custom containers
- **Optional Archestra.ai** - AI agent security platform (feature flag)

### Design Philosophy

This template uses a bare VM approach for Terminal Jarvis development:

1. **Fast Initial Connection** - Minimal startup script installs only curl and ca-certificates
2. **Agent-First** - Coder agent starts within ~30 seconds and connects to Coder server
3. **Progressive Enhancement** - Development tools (Rust, Python, Node.js, code-server) install in the background after the agent connects
4. **Full Tooling** - All Terminal Jarvis dependencies pre-configured (Rust 1.87+, Python with uv, Node.js 20)
5. **Optional Features** - Docker and Archestra.ai can be enabled via feature flags
6. **Easy Debugging** - Direct SSH access, systemd service logs via journalctl

The full filesystem is preserved when the workspace restarts, as Coder persists the root volume.

### Archestra.ai Integration

When enabled (`enable_archestra = true`), this template:
- Installs Docker daemon
- Runs Archestra platform container with ports 3000 (UI) and 9000 (API proxy)
- Exposes Archestra UI and API as Coder apps in the dashboard
- Sets `ARCHESTRA_API_BASE_URL` environment variable for Terminal Jarvis integration

Use Archestra to add security guardrails to AI agent interactions:
- Dynamic tools based on content trust
- Dual LLM quarantine for prompt injection prevention
- Proxy LLM requests through `http://localhost:9000/v1/anthropic` or `http://localhost:9000/v1/openai`

## Prerequisites

### 1. Service Account Setup

Create a GCP Service Account with appropriate permissions:

1. Navigate to the [GCP Console](https://console.cloud.google.com/)
2. Select your Cloud project
3. Go to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Provide a service account name and click **Create and continue**
6. Grant the following IAM roles:
   - **Compute Admin**
   - **Service Account User**
7. Click **Continue** → **Done**
8. Click on the created service account → **Keys** tab
9. Click **Add Key** → **Create new key**
10. Select **JSON** and download the key file

### 2. Authentication Options

This template supports two authentication methods:

#### Option A: Per-Workspace Credentials (Recommended for individual use)

When creating a workspace, you'll paste the JSON key content into Coder's UI:

1. Open your downloaded JSON key file in a text editor
2. Copy the entire contents (including the curly braces)
3. When creating a workspace in Coder, paste this into the `gcp_credentials` field
4. Coder stores this securely and marks it as sensitive

**Security Notes:**
- Never commit JSON key files to git repositories
- The `gcp_credentials` variable is marked as sensitive (won't appear in logs)
- Each workspace can use different credentials if needed

#### Option B: Server-Level Ambient Credentials (For shared Coder deployments)

If your Coder server runs in an authenticated GCP environment:

```bash
# On the machine running coderd
gcloud auth application-default login

# OR set environment variable
export GOOGLE_CREDENTIALS="$(cat /path/to/key.json)"
```

When using ambient credentials, leave the `gcp_credentials` template variable empty. The provider will automatically use the server's authentication.

For other authentication methods, see [Terraform GCP Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

## Setup Instructions

### 1. Prepare the Template

From the repository root:

```bash
cd terminal-jarvis-playground/gcp
tar -cf ../terminal-jarvis-playground-gcp.tar .
cd ../..
```

This creates `terminal-jarvis-playground/terminal-jarvis-playground-gcp.tar`.

### 2. Upload to Coder

1. Navigate to your Coder dashboard
2. Go to **Templates** → **Create Template**
3. Upload `terminal-jarvis-playground-gcp.tar`
4. Configure template variables:

   - `project_id`: Your GCP project ID (required)
   - `gcp_credentials`: Service account JSON key content (optional - paste entire JSON file contents)
   - `zone`: GCP zone (default: `us-central1-a`)
   - `machine_type`: VM size (default: `e2-micro`)
   - `disk_size`: Persistent disk size in GB (default: `16`)
   - `enable_archestra`: Enable Archestra.ai platform (default: `false`)
   - `enable_docker`: Enable Docker daemon (default: `false`)

### 3. Create Workspace

1. Click **Create Workspace** from the template
2. Wait for provisioning to complete
3. Access code-server through the Coder dashboard

## Cost Considerations

### Free Tier (e2-micro)

GCP offers an Always Free tier with:
- 1 non-preemptible `e2-micro` instance per month
- 30 GB standard persistent disk
- Limited to specific regions (us-west1, us-central1, us-east1)

To use free tier, set:
```hcl
machine_type = "e2-micro"
disk_size    = 30
zone         = "us-central1-a"  # or us-west1-b, us-east1-b
```

### Cost Optimization

- Stop workspaces when not in use (VM is ephemeral)
- Persistent disk charges apply even when stopped (~$1.70/month for 30GB)
- Use `e2-micro` for light workloads
- Upgrade to `e2-medium` or `e2-standard-2` for better performance

## Accessing Your Workspace

Once the workspace starts:

1. **Code-Server**: Click the "code-server" app in the Coder dashboard
2. **SSH**: Use `coder ssh <workspace-name>` from your terminal
3. **VS Code Remote**: Install Coder extension and connect

## Customization

### Adding More Tools

Edit the `startup_script` in the `coder_agent` resource in `main.tf`:

```hcl
startup_script = <<-EOT
  set -e

  # Install additional tools after agent connects
  if [ ! -f ~/.tools_installed ]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git \
      wget \
      vim \
      htop \
      build-essential \
      your-package-here

    touch ~/.tools_installed
  fi

  # Your custom startup commands here
  npm install -g your-global-tool

  # code-server installation (already included)
  if ! command -v code-server &> /dev/null; then
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.96.2
  fi
EOT
```

### Machine Type Options

Common machine types:
- `e2-micro`: 2 vCPUs, 1 GB RAM (Free tier eligible)
- `e2-small`: 2 vCPUs, 2 GB RAM
- `e2-medium`: 2 vCPUs, 4 GB RAM (Default)
- `e2-standard-2`: 2 vCPUs, 8 GB RAM
- `e2-standard-4`: 4 vCPUs, 16 GB RAM

## Troubleshooting

### Workspace fails to start

Check:
1. Service account has correct IAM roles (Compute Admin, Service Account User)
2. Project ID is correct
3. Zone/region quota limits
4. GCP API is enabled (Compute Engine API)

### Agent not connecting

SSH into the VM to debug:

```bash
# List running instances
gcloud compute instances list --project=YOUR_PROJECT_ID

# SSH into the VM
gcloud compute ssh INSTANCE_NAME --zone=ZONE --project=PROJECT_ID

# Check startup script logs
sudo journalctl -u google-startup-scripts.service --no-pager | tail -100

# Check agent service status
sudo systemctl status coder-agent

# View agent logs in real-time
sudo journalctl -u coder-agent -f

# Check if coder user was created
id coder

# Verify agent init script exists
ls -lh /opt/coder-agent-init.sh
```

### Code-server not appearing

1. Wait ~60-90 seconds for initial tool installation to complete
2. Check agent logs: `sudo journalctl -u coder-agent -f`
3. Verify code-server is running: `sudo systemctl status coder-agent` should show code-server process
4. Check for "apphealth: workspace app healthy" messages in agent logs

### Persistent disk not mounting

1. Verify disk exists in GCP Console
2. Check disk is in the same zone as the instance
3. Ensure disk isn't attached to another instance

### Slow startup on e2-micro

The e2-micro instance (1 GB RAM) can be slow to install packages. The agent connects quickly (~30 seconds), but background tool installation (Rust, Python, Node.js, build-essential) may take 10-15 minutes. Consider using e2-medium for faster setup.

### Archestra container not starting

1. Verify Docker is enabled: `enable_docker = true` or `enable_archestra = true`
2. Check Docker daemon status: `sudo systemctl status docker`
3. View container logs: `docker logs archestra-platform`
4. Ensure ports 3000 and 9000 are not in use: `sudo netstat -tulpn | grep -E ':(3000|9000)'`

### Rust commands not found

The Rust environment is installed per-user. Ensure your shell has loaded the Cargo environment:

```bash
source ~/.cargo/env
```

This is automatically done in the startup script, but if you switch shells or users, you may need to source it again.

## Architecture Details

### Ephemeral vs Persistent

- **Ephemeral**: GCP Compute Instance (deleted on stop, recreated on start)
- **Persistent**: Root disk (survives workspace restarts)

This design saves costs by only charging for compute when the workspace is active, while preserving all files and configurations on the persistent disk.

### Networking

The instance uses GCP's default network with an ephemeral public IP. The IP changes each time the workspace starts, but Coder's agent handles reconnection automatically.

## Related Documentation

- [Coder GCP Template Docs](https://coder.com/docs/templates/providers/google-cloud-platform)
- [GCP Compute Engine Pricing](https://cloud.google.com/compute/pricing)
- [GCP Always Free Tier](https://cloud.google.com/free)
