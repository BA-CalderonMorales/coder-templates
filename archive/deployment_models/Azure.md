# Azure Deployment Model (Free / Low-Cost)

This guide covers deploying the `terminal-jarvis-playground` Coder template on Azure using low-cost resources (12‑month free services + minimal consumption). Azure's always-free is more limited than GCP; careful sizing and shutdown policies help control spend.

## Overview
Azure 12‑month free tier includes:
- B1s VM (1 vCPU, 1 GiB RAM) for 750 hours/month
- 64 GB of standard storage (pooled across services)

For a comfortable JetBrains experience you generally need ≥2–3 GiB RAM; start with code-server only on B1s. Upgrade later to B2s or D2as_v5.

## Architecture
Single Azure VM (Ubuntu LTS) running:
- Docker Engine
- (Option A) Coder server + workspace container
- (Option B) Workspace node only; Coder central elsewhere (e.g. container app / other VM)

Data: Managed disk (OS) + optional separate data disk (not required for small setups). User home persisted via Docker volume or host bind.

## Trade-Offs vs Other Clouds
| Area | Azure B1s | Note |
|------|-----------|------|
| CPU Credits | Burstable | Sustained high load throttles |
| Disk Perf | Standard SSD/HDD | Keep layers small |
| Network | Generally fine | Watch outbound to other regions |

## Prerequisites
- Azure subscription with free tier eligibility
- Azure CLI logged in: `az login`

## Step 1: Resource Group
```bash
az group create -n coder-rg -l eastus
```

## Step 2: Create VM
```bash
az vm create \
  --resource-group coder-rg \
  --name coder-dev \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --os-disk-size-gb 30
```
Capture public IP:
```bash
IP=$(az vm show -d -g coder-rg -n coder-dev --query publicIps -o tsv)
echo $IP
```

## Step 3: Open Ports (Restrict Your IP)
```bash
az network nsg rule create \
  --resource-group coder-rg \
  --nsg-name coder-devNSG \
  --name allow-coder \
  --priority 200 \
  --destination-port-ranges 7080 \
  --protocol Tcp \
  --access Allow \
  --source-address-prefixes YOUR_IP_ADDRESS \
  --direction Inbound
```
(SSH port 22 already open to your IP by default if created with CLI flags.)

## Step 4: Install Docker & Swap
```bash
ssh azureuser@$IP
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker azureuser
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Step 5A: Install Coder On Same VM
```bash
curl -fsSL https://coder.com/install.sh | sh
coder server --accept-tos &
```
Add a reverse proxy w/ TLS (Azure Application Gateway, Nginx + Let's Encrypt, or Azure Front Door) for production.

## Step 5B: Remote Workspace Mode
Expose Docker TLS on this VM and configure Terraform provider variables (`docker_host`, cert materials).

## Step 6: Build & Tag Workspace Image
```bash
cd terminal-jarvis-playground
docker build -t coder-terminal-jarvis-playground:latest .
```
Optionally push to Azure Container Registry (ACR):
```bash
az acr create -g coder-rg -n coderDevRegistry --sku Basic
az acr login -n coderDevRegistry
ACR_LOGIN=$(az acr show -n coderDevRegistry --query loginServer -o tsv)
docker tag coder-terminal-jarvis-playground:latest $ACR_LOGIN/coder-terminal-jarvis-playground:latest
docker push $ACR_LOGIN/coder-terminal-jarvis-playground:latest
```
Set Terraform variable `workspace_image` accordingly.

## Step 7: Terraform Apply
```bash
terraform init
terraform apply -auto-approve \
  -var enable_jetbrains_gateway=false \
  -var memory_limit_mb=768
```

## Auto-Shutdown (Optional Savings)
Use Azure Dev/Test auto-shutdown feature or create an Automation Account schedule to stop the VM nightly:
```bash
az vm auto-shutdown -g coder-rg -n coder-dev --time 2300 --email you@example.com
```

## Cost Watchlist
| Item | Notes |
|------|-------|
| VM Hours | Keep single B1s within 750 free hours |
| Disk | OS disk 30 GB; avoid large Docker layer bloat |
| Outbound Data | Mirror repos locally; minimize large downloads |

## Hardening
- Restrict NSG rules to specific IPs
- Enable Azure Defender (optional, may incur cost) for production
- Use Managed Identity instead of access keys for pulling from ACR

## Troubleshooting
| Issue | Symptom | Fix |
|-------|---------|-----|
| Throttled CPU | High load builds slow | Pause tasks / upgrade to B2s |
| OOM | Container exits | Add swap / reduce services |
| Slow Pulls | Image downloads lag | Store image in regional ACR |

## Upgrade Path
- Move to Standard_B2s (2 vCPU, 4 GiB) to enable JetBrains
- Attach Premium SSD for faster build caching
- Centralize Coder server in Azure Container Apps / AKS

---
Last updated: 2025-09-18
