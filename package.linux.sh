#!/bin/bash

set -e

echo "Coder Template Packaging Script"
echo "================================"
echo ""
echo "Available templates:"
echo "  1) local-docker - Local Docker deployment"
echo "  2) gcp - Google Compute Engine deployment"
echo "  3) all - Package both templates"
echo ""

if [ -z "$1" ]; then
  read -p "Select template to package (1/2/3): " choice
else
  choice="$1"
fi

case "$choice" in
  1|local-docker)
    echo "Packaging local-docker template..."
    cd terminal-jarvis-playground/local-docker
    tar -cf ../../terminal-jarvis-playground-local.tar --exclude='.terraform' --exclude='.terraform.lock.hcl' .
    cd ../..
    echo "Created: terminal-jarvis-playground-local.tar"
    ;;
  2|gcp)
    echo "Packaging gcp template..."
    cd terminal-jarvis-playground/gcp
    tar -cf ../../terminal-jarvis-playground-gcp.tar \
      --exclude='.terraform' \
      --exclude='.terraform.lock.hcl' \
      --exclude='*.backup-*' \
      --exclude='Dockerfile' \
      .
    cd ../..
    echo "Created: terminal-jarvis-playground-gcp.tar"
    ;;
  3|all)
    echo "Packaging all templates..."
    cd terminal-jarvis-playground/local-docker
    tar -cf ../../terminal-jarvis-playground-local.tar --exclude='.terraform' --exclude='.terraform.lock.hcl' .
    cd ../gcp
    tar -cf ../../terminal-jarvis-playground-gcp.tar \
      --exclude='.terraform' \
      --exclude='.terraform.lock.hcl' \
      --exclude='*.backup-*' \
      --exclude='Dockerfile' \
      .
    cd ../..
    echo "Created: terminal-jarvis-playground-local.tar"
    echo "Created: terminal-jarvis-playground-gcp.tar"
    ;;
  *)
    echo "Invalid choice. Please select 1, 2, or 3."
    exit 1
    ;;
esac

echo ""
echo "Packaging complete!"
