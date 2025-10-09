FROM ubuntu:22.04

LABEL description="GCP Development environment for Terminal-Jarvis with code-server"
LABEL project="terminal-jarvis"
LABEL maintainer="coder"
LABEL provider="gcp"

USER root

# Install essential development tools for Terminal-Jarvis
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    git \
    git-lfs \
    build-essential \
    pkg-config \
    libssl-dev \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    sudo \
    gnupg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create coder user
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER coder
WORKDIR /home/coder

# Install Rust toolchain for coder user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.87.0 \
    && . "$HOME/.cargo/env" \
    && rustup component add clippy rustfmt

# Install uv (Python package manager) for coder user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install code-server as coder user
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Set up environment
ENV PATH="/home/coder/.cargo/bin:$PATH"
ENV RUST_LOG="debug"
ENV CARGO_TERM_COLOR="always"
ENV CARGO_INCREMENTAL="1"
ENV RUST_BACKTRACE="1"

# Add Terminal Jarvis custom PS1 prompt
RUN cat >> ~/.bashrc << 'EOF'

# Terminal Jarvis Custom PS1
COL_USER='\[\e[96m\]'      # Cyan for [me]
COL_PATH='\[\e[93m\]'      # Yellow for path
COL_BRANCH='\[\e[92m\]'    # Green for branch
COL_BRACKETS='\[\e[90m\]'  # Dark gray for brackets
COL_RESET='\[\e[0m\]'      # Reset color

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

set_bash_prompt() {
    local branch=$(parse_git_branch)
    if [ -n "$branch" ]; then
        PS1="${COL_BRACKETS}[${COL_USER}me${COL_BRACKETS}]:${COL_PATH}\w ${COL_BRACKETS}(${COL_BRANCH}$branch${COL_BRACKETS}): ${COL_RESET}"
    else
        PS1="${COL_BRACKETS}[${COL_USER}me${COL_BRACKETS}]:${COL_PATH}\w${COL_BRACKETS}: ${COL_RESET}"
    fi
}

PROMPT_COMMAND=set_bash_prompt
EOF

# Add Terminal Jarvis welcome message
RUN cat >> ~/.bashrc << 'EOF'

# Terminal Jarvis Development Welcome
if [ "$TERM" != "dumb" ] && [ -t 1 ]; then
    echo ""
    echo "Welcome to Terminal Jarvis development!"
    echo "Environment: Rust $(rustc --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A') + Node.js $(node --version 2>/dev/null || echo 'N/A') + Python $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"
    echo "Package managers: npm $(npm --version 2>/dev/null || echo 'N/A') + uv $(uv --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A') + pip $(pip3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"
    echo ""
    echo "Available commands:"
    echo "  cargo check             # Verify Rust compilation"
    echo "  cargo run -- --help     # Terminal Jarvis help"
    echo "  cargo run -- list       # List AI tools"
    echo "  cargo test              # Run all tests"
    echo ""
fi
EOF

# Expose code-server port
EXPOSE 13337

CMD ["/bin/bash"]
