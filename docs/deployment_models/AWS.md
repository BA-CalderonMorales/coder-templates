# AWS Deployment Model (Free-Tier Friendly)

This guide explains how to deploy the `terminal-jarvis-playground` Coder template on AWS using the 12‑month free tier (t2.micro or t4g.micro) while minimizing costs.

## Overview
AWS free tier (first 12 months) includes 750 hours/month of:
- t2.micro (x86) or t4g.micro (ARM/Graviton2) EC2 instance
- 30 GB of EBS (general purpose)

JetBrains IDE backends typically need more than 1 GiB RAM. Start with `code-server` only and later move to a larger instance (e.g., t3.small / t3.medium) for JetBrains.

## Architecture
Single EC2 instance:
- Docker Engine
- (Option A) Coder server + workspace container
- (Option B) Workspace node only; Coder server hosted centrally

Storage via one gp3 (or gp2) EBS volume (20–30 GB). Optional additional volume for user data.

## Choosing t2.micro vs t4g.micro
| Type | Arch | Pros | Cons |
|------|------|------|------|
| t2.micro | x86_64 | Compatible with most images | Older burst model |
| t4g.micro | arm64 | Faster per-dollar; efficient | Need multi-arch image |

If using `t4g.micro`, ensure your Docker image is built for `linux/arm64`.

## Prerequisites
- AWS account (within 12‑month free tier window)
- IAM user/role with EC2 & ECR access
- AWS CLI configured (`aws configure`)

## Step 1: Security Group
```bash
aws ec2 create-security-group --group-name coder-sg --description "Coder SG"
SG_ID=$(aws ec2 describe-security-groups --group-names coder-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr YOUR_IP/32
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 7080 --cidr YOUR_IP/32
```
(Restrict to your IP; later use reverse proxy + TLS.)

## Step 2: Launch Instance
```bash
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' 'Name=state,Values=available' \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)
aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type t2.micro \
  --security-group-ids $SG_ID \
  --key-name YOUR_KEYPAIR_NAME \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=coder-dev}]' \
  --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}
```
Grab the public IP once running:
```bash
aws ec2 describe-instances --filters 'Name=tag:Name,Values=coder-dev' --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

## Step 3: Install Docker & (Optional) Swap
```bash
ssh ubuntu@PUBLIC_IP
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu
# Re-login or: exec su -l ubuntu
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Step 4A: Install Coder Locally
```bash
curl -fsSL https://coder.com/install.sh | sh
coder server --accept-tos &
```
Create an admin token and log in via the public IP (port 7080). Add TLS ASAP.

## Step 4B: Remote Workspace Mode
If using a centralized Coder deployment, configure Docker over TLS and feed cert materials to Terraform variables.

## Step 5: Build Multi-Arch Image (Optional)
If you plan to support both x86_64 and arm64 for portability:
```bash
# Enable buildx
docker buildx create --use --name multi
docker buildx inspect --bootstrap
# Build multi-arch image
cd terminal-jarvis-playground
docker buildx build --platform linux/amd64,linux/arm64 -t YOUR_ACCOUNT/terminal-jarvis:latest --push .
```
Set Terraform variable `workspace_image` to the pushed image name.

## Step 6: Terraform Apply
Inside the instance (or anywhere with access & credentials):
```bash
cd terminal-jarvis-playground
terraform init
terraform apply -auto-approve \
  -var enable_jetbrains_gateway=false \
  -var memory_limit_mb=768
```

## Cost Watchlist
| Item | Notes |
|------|-------|
| Instance hours | Stay within 750 h/mo (one instance always-on is fine) |
| EBS | Keep <= 30 GB; clean unused layers/images |
| Data Transfer | Pull large images sparingly; enable layer caching |
| Elastic IP | Avoid unattached EIP (charges) |

## Hardening Tips
- Put Coder behind ALB or Nginx with HTTPS (Let’s Encrypt / ACM)
- Disable password SSH auth (Key-only)
- Regularly patch: `sudo unattended-upgrades` on Ubuntu

## Troubleshooting
| Issue | Symptom | Resolution |
|-------|---------|------------|
| OOM | Container killed under load | Add swap / prune processes |
| Slow Image Builds | High CPU steal | Change AZ / upgrade to t3.small |
| Can't Pull Multi-Arch | Platform mismatch | Use `--platform` flag or buildx |

## Upgrade Path
- Move to t3.small (2 vCPU, 2 GiB) for JetBrains support
- Add EFS for shared home directories across workspaces
- Use AWS Systems Manager Session Manager instead of direct SSH

---
Last updated: 2025-09-18
