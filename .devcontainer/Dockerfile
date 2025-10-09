FROM ubuntu:22.04

# Install essential development tools for Coder templates
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    git-lfs \
    build-essential \
    ca-certificates \
    sudo \
    jq \
    unzip \
    lsb-release \
    gnupg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform (latest stable)
# Use /etc/os-release to get the distro codename instead of lsb_release which
# may not be available in minimal build images. This prevents creating a
# malformed apt sources list entry.
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && . /etc/os-release && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for building workspace images)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && . /etc/os-release && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install gcloud CLI (for GCP deployments)
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update && apt-get install -y google-cloud-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create codespace user for GitHub Codespaces compatibility
# Only add user to docker group if it exists (for local Docker usage).
# If docker isn't installed or group doesn't exist, skip without failing.
RUN groupadd --gid 1000 codespace \
    && useradd --uid 1000 --gid codespace --shell /bin/bash --create-home codespace \
    && echo 'codespace ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && (getent group docker >/dev/null && usermod -aG docker codespace || true)

USER codespace
WORKDIR /workspaces/coder-templates