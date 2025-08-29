# Coder Templates

This repository contains templates and utilities for creating consistent development environments using Coder.

## Purpose

The `start.windows.sh` script is used to package the Terminal-Jarvis development environment template into a portable tar archive. This archive can then be imported into Coder to create consistent development environments across the team.

### Current Template

- `terminal-jarvis-playground`: A development environment for Terminal-Jarvis with Node.js and Git support.

### Usage

To package the template environment:

```bash
./start.windows.sh
```

This will create:
- `terminal-jarvis-playground.tar`: Contains the basic Node.js development environment

### Template Structure

The template directory contains:
- `Dockerfile`: Defines the development environment
- `main.tf`: Terraform configuration for the Coder workspace
- Additional configuration files as needed
