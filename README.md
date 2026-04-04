# Nitroberry DevOps - Traefik Production Stack

**Project Status:** ✅ Production-ready
**Architecture:** Traefik v3 API Gateway (Replacing NGINX)
**Autoscaling:** Dynamic Horizontal Scaling (2-10 Replicas, 70% CPU Threshold)
**Orchestration:** Docker Swarm Mode

---

## 🏗️ Architecture Overview
This production-grade stack utilizes **Traefik v3** for intelligent edge routing, automatic Let's Encrypt SSL termination (via HTTP/TLS challenges), and round-robin load balancing. The application fleet is orchestrated by Docker Swarm, ensuring high availability and seamless rolling updates.

### Key Files List
- `docker-compose.yml`: Main stack orchestration and resource definitions.
- `autoscale.sh`: Production monitoring loop for horizontal service scaling.
- `deploy.sh`: Unified deployment and network initialization script.
- `.env`: Global environment configuration and registry credentials.
- `traefik/traefik.yml`: Static configuration for the Traefik v3 gateway.

---

## 📊 Stack Overview

### Service Architecture
| Service | Image | Role | Replicas |
| :--- | :--- | :--- | :--- |
| **traefik** | `traefik:v3.0` | SSL Gateway / Entrypoint | 1 (Manager) |
| **nb-api** | `${CR_REGISTRY}/nb-api` | Main Application API | **2 - 10** |
| **nb-worker** | `${CR_REGISTRY}/nb-worker` | Background Processing | 1 |
| **nb-cron** | `${CR_REGISTRY}/nb-cron` | Scheduled Task Runner | 1 |
| **nb-socket** | `${CR_REGISTRY}/nb-socket` | Real-time WebSocket Service | 1 |
| **nb-redis** | `redis:8-alpine` | Shared State / Caching | 1 |

### Autoscaling Configuration
| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Min Replicas** | 2 | Minimum capacity for high availability |
| **Max Replicas** | 10 | Maximum burst capacity under load |
| **Scale Up** | > 70% CPU | Increments replicas when CPU is high |
| **Scale Down** | < 30% CPU | Decrements replicas to save resources |
| **Check Filter** | `nb-stack_nb-api` | Target service for monitoring |

---

## 🚀 Quick Start (Production)

### 1. Initialize the Cluster
```bash
docker swarm init
```

### 2. Prepare Environment
```bash
cp .env.template .env
# Update .env with your DOMAIN and LETSENCRYPT_EMAIL
```

### 3. Deploy the Stack
```bash
./deploy.sh
```

### 4. Enable Real-time Scaling
```bash
./autoscale.sh
```

---

## 🔁 Production Deployment Commands
| Action | Command |
| :--- | :--- |
| **Deploy/Update Stack** | `docker stack deploy -c docker-compose.yml nb-stack` |
| **Check Service Health** | `docker stack services nb-stack` |
| **View Gateway Logs** | `docker service logs -f nb-stack_traefik` |
| **Force Service Update** | `docker service update --force nb-stack_nb-api` |
| **Remove Entire Stack** | `docker stack rm nb-stack` |

---

## ☁️ AWS Deployment (EC2/ECR)
To use custom images from your private AWS registry, authenticate before deploying:
```bash
aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-account-id.dkr.ecr.your-region.amazonaws.com
```

Ensure your EC2 Security Groups allow incoming traffic on ports `80` (HTTP), `443` (HTTPS), and the Docker Swarm communication ports if using a multi-node cluster.

---
*Maintained by the Nitroberry DevOps Team*
