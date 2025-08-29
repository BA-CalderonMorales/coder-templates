FROM codercom/enterprise-base:ubuntu

LABEL description="Development environment for Terminal-Jarvis"
LABEL project="terminal-jarvis"
LABEL maintainer="coder"

# Install Node.js and Git
RUN apt-get update && \
    apt-get install -y curl git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*