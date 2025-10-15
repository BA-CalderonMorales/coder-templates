### Key Features

### - Persistent Storage: Root disk persists between sessions
### - Code-Server IDE: VS Code accessible through browser
### - System Monitoring: Real-time resource usage in the dashboard
### - Git Integration: Automatically configured with your user details
### - GCP Compute Engine: Ephemeral VM instances with persistent disk

### This template creates a GCP Compute Engine development environment with code-server, persistent storage, and professional development tools.

### Provider Configuration
terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

locals {
  username = data.coder_workspace_owner.me.name
}

### Variables
variable "project_id" {
  description = <<-EOT
    GCP project ID

    Find your project ID: https://console.cloud.google.com/welcome?project=terminal-jarvis-playground
  EOT
  type        = string
}

variable "zone" {
  description = "GCP zone (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP machine type (e.g., e2-micro for free tier)"
  type        = string
  default     = "e2-micro"
}

variable "disk_size" {
  description = "Persistent disk size in GB"
  type        = number
  default     = 16
}

variable "gcp_credentials" {
  description = "GCP service account JSON key content (optional - falls back to ambient credentials if not provided)"
  type        = string
  default     = null
  sensitive   = true
}

### Data Sources
provider "google" {
  project     = var.project_id
  zone        = var.zone
  credentials = var.gcp_credentials
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

### Coder Agent
resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi

    # Add any commands that should be executed at workspace startup here
  EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    script       = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval     = 60
    timeout      = 1
  }
}

### Development Tools
### Code-Server module provides VS Code in the browser
module "code-server" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/modules/code-server/coder"
  version = "~> 1.0"

  agent_id = coder_agent.main.id
  order    = 1
}

### GCP Infrastructure

# Firewall rule to allow SSH access for debugging
resource "google_compute_firewall" "allow_ssh" {
  name    = "coder-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["coder-workspace"]
}

# Persistent root disk
resource "google_compute_disk" "root" {
  name  = "coder-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}-root"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.disk_size
  image = "ubuntu-os-cloud/ubuntu-2204-lts"

  lifecycle {
    ignore_changes = [image]
  }

  labels = {
    "coder_owner"          = lower(data.coder_workspace_owner.me.name)
    "coder_owner_id"       = lower(data.coder_workspace_owner.me.id)
    "coder_workspace_id"   = lower(data.coder_workspace.me.id)
    "coder_workspace_name" = lower(data.coder_workspace.me.name)
  }
}

# Ephemeral compute instance
resource "google_compute_instance" "workspace" {
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}"
  machine_type = var.machine_type
  zone         = var.zone

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["coder-workspace"]

  boot_disk {
    source      = google_compute_disk.root.self_link
    auto_delete = false
  }

  metadata = {
    "coder_owner"          = data.coder_workspace_owner.me.name
    "coder_owner_id"       = data.coder_workspace_owner.me.id
    "coder_workspace_id"   = data.coder_workspace.me.id
    "coder_workspace_name" = data.coder_workspace.me.name
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail

    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
      curl -fsSL https://get.docker.com | sh
      systemctl enable docker
      systemctl start docker
    fi

    # Create persistent home directory on host
    mkdir -p /home/coder

    # Stop and remove any existing container
    CONTAINER_NAME="coder-${lower(data.coder_workspace_owner.me.name)}-${lower(data.coder_workspace.me.name)}"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

    # Pull the workspace image (use ubuntu:22.04 as fallback for now)
    # TODO: Replace with actual image from registry
    if ! docker image inspect coder-terminal-jarvis-playground:latest &> /dev/null; then
      docker pull ubuntu:22.04
      docker tag ubuntu:22.04 coder-terminal-jarvis-playground:latest
    fi

    # Run the workspace container with the Coder agent
    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -e CODER_AGENT_TOKEN="${coder_agent.main.token}" \
      -v /home/coder:/home/coder \
      coder-terminal-jarvis-playground:latest \
      sh -c "${coder_agent.main.init_script}"
  SCRIPT

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  labels = {
    "coder_owner"          = lower(data.coder_workspace_owner.me.name)
    "coder_owner_id"       = lower(data.coder_workspace_owner.me.id)
    "coder_workspace_id"   = lower(data.coder_workspace.me.id)
    "coder_workspace_name" = lower(data.coder_workspace.me.name)
  }
}
