# Nitroberry DevOps - Traefik Production Stack

**Project Status:** ✅ PRODUCTION READY
**Architecture:** Traefik v3 API Gateway + Docker Swarm (SSL Auto-renewal)
**Autoscaling:** Horizontal Scaling (2-10 Replicas, 70% threshold)

---

## ⚡ Step-by-Step Deployment (For Freshers)

Follow these exact steps to deploy the stack on a fresh AWS EC2 instance.

### 1. Prepare your AWS EC2
- **Instance Type:** Minimum `t3.medium` (2 vCPU, 4GB RAM).
- **Security Group:** Open ports `80` (HTTP), `443` (HTTPS), and `22` (SSH).
- **Docker Installation:**
  ```bash
  sudo apt update && sudo apt install docker.io -y
  sudo usermod -aG docker $USER && newgrp docker
  ```

### 2. Clone and Enter Project
```bash
git clone https://github.com/abhimanyu8829/Nitroberry_DevOps_CICD.git
cd Nitroberry_DevOps_CICD
```

### 3. Configure Environment (`.env`)
Create your production `.env` file and update these **3 key values**:
```bash
cp .env.template .env
nano .env
```
**Required Changes:**
- `DOMAIN`: Change to your actual domain (e.g., `api.nitroberry.com`)
- `LETSENCRYPT_EMAIL`: Your email for SSL renewal alerts.
- `CR_REGISTRY`: Your AWS ECR URI (e.g., `12345678.dkr.ecr.us-east-1.amazonaws.com`)

### 4. Deploy the Stack
Initialize Swarm mode and run the unified deployment script.
```bash
docker swarm init
chmod +x deploy.sh
./deploy.sh
```

### 5. Start Autoscaling
This script will keep your API running between 2 and 10 replicas based on traffic.
```bash
chmod +x autoscale.sh
nohup ./autoscale.sh > autoscale.log 2>&1 &
```

---

## 📊 Stack Overview

### Service Architecture
| Service | Image | Role | Replicas |
| :--- | :--- | :--- | :--- |
| **traefik** | `traefik:v3.0` | Gateway & SSL Termination | 1 |
| **nb-api** | `${CR_REGISTRY}/nb-api` | Main API Service | **2 - 10** |
| **nb-worker** | `${CR_REGISTRY}/nb-worker` | Background Tasks | 1 |
| **nb-cron** | `${CR_REGISTRY}/nb-cron` | CRON Engine | 1 |
| **nb-socket** | `${CR_REGISTRY}/nb-socket` | WebSockets | 1 |
| **nb-redis** | `redis:8-alpine` | Cache / Session Store | 1 |

### Autoscaling Configuration
| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Scale Up** | > 70% CPU | Adds 1 replica (up to 10) |
| **Scale Down** | < 30% CPU | Removes 1 replica (down to 2) |
| **Check Period** | 30 Seconds | Frequency of CPU health checks |

---

## 🔁 Production Management
| Action | Command |
| :--- | :--- |
| **Check Status** | `docker stack services nb-stack` |
| **View API Logs** | `docker service logs -f nb-stack_nb-api` |
| **View Gateway Logs** | `docker service logs -f nb-stack_traefik` |
| **HTTPS Dashboard** | `https://traefik.yourdomain.com` |
| **Monitor Replicas** | `docker service ps nb-stack_nb-api` |

---
*Maintained by the Nitroberry DevOps Team*
