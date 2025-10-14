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

    # Install code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

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

### Code-Server App
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

### GCP Infrastructure

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

  metadata_startup_script = coder_agent.main.init_script

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
