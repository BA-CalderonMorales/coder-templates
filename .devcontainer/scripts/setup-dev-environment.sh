#!/bin/bash
set -e

echo "Setting up Coder Templates development environment..."

# Verify installations
echo "Development environment verification:"

echo "Terraform:"
terraform version

echo "Docker CLI:"
docker --version

echo "gcloud CLI:"
gcloud version

echo "GitHub CLI:"
gh --version

echo "Git:"
git --version
git lfs version

# Initialize git-lfs for the user (force update to handle existing hooks)
echo "Initializing Git LFS..."
git lfs update --force || echo "Git LFS initialization failed (non-blocking)"

# Install terminal-jarvis as a consumer tool (optional, for AI-assisted development)
echo "Installing terminal-jarvis for AI-assisted development..."
if command -v cargo &> /dev/null; then
    echo "Rust already installed, terminal-jarvis can be used"
else
    echo "Installing Rust for terminal-jarvis..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck disable=SC1090
    . "$HOME/.cargo/env"
fi

# Add Rust to PATH if not already there
if ! grep -q '.cargo/env' ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi

# Add custom PS1 prompt for coder-templates
if ! grep -q "# Coder Templates Custom PS1" ~/.bashrc; then
    echo "Adding custom PS1 prompt..."
    # shellcheck disable=SC2016
    cat >> ~/.bashrc << 'EOF'

# Coder Templates Custom PS1
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
else
    echo "Custom PS1 prompt already present in bashrc."
fi

# Add welcome message
WELCOME_MARKER="# Coder Templates Development Welcome"
if ! grep -q "$WELCOME_MARKER" ~/.bashrc; then
    echo "Adding Coder Templates development prompt..."
    # shellcheck disable=SC2016
    cat >> ~/.bashrc << 'EOF'

# Coder Templates Development Welcome
if [ "$TERM" != "dumb" ] && [ -t 1 ]; then
    echo ""
    echo "Welcome to Coder Templates development!"
    echo "Tools: Terraform $(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'N/A') + Docker $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'N/A') + gcloud $(gcloud version 2>/dev/null | head -n1 | cut -d' ' -f4 || echo 'N/A')"
    echo ""
    echo "Available commands:"
    echo "  terraform fmt           # Format Terraform files"
    echo "  terraform validate      # Validate Terraform config"
    echo "  docker build            # Build workspace images"
    echo "  gcloud auth login       # Authenticate with GCP"
    echo "  gh auth login           # Authenticate with GitHub"
    echo ""
    echo "Packaging templates:"
    echo "  cd terminal-jarvis-playground/local-docker && tar -cf ../../terminal-jarvis-playground-local.tar ."
    echo "  cd terminal-jarvis-playground/gcp && tar -cf ../terminal-jarvis-playground-gcp.tar ."
    echo ""
fi
EOF
else
    echo "Coder Templates welcome prompt already present in bashrc."
fi

echo ""
echo "Development environment setup complete!"
echo "Run 'source ~/.bashrc' to apply changes to your current shell."