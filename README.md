# 🚀 Nitroberry DevOps - Traefik & Swarm Production Stack

[![Docker Swarm](https://img.shields.io/badge/Orchestration-Docker_Swarm-blue.svg)](https://docs.docker.com/engine/swarm/)
[![Traefik v3](https://img.shields.io/badge/Gateway-Traefik_v3-blueviolet.svg)](https://doc.traefik.io/traefik/)
[![SSL](https://img.shields.io/badge/SSL-Auto_LetsEncrypt-green.svg)](https://letsencrypt.org/)

This repository contains the production-ready infrastructure for **Nitroberry**, featuring an automated API gateway, auto-renewing SSL certificates, and intelligent horizontal autoscaling.

---

## 🚦 How Traffic is Managed

Traefik acts as the entry point for all incoming traffic. It automatically distributes requests across all running API containers using a **Round Robin** algorithm.

### Traffic Flow Diagram
```text
                    ┌─────────────────────────────────────┐
                    │           INCOMING REQUESTS          │
                    │      https://api.yourdomain.com     │
                    └─────────────────┬───────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────────┐
                    │            TRAEFIK (Port 443)       │
                    │         Round Robin Load Balancer   │
                    └─────────────────┬───────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
┌───────────────┐             ┌───────────────┐             ┌───────────────┐
│   API Pod 1   │             │   API Pod 2   │             │   API Pod 3   │
│  (Container)  │             │  (Container)  │             │  (Container)  │
└───────────────┘             └───────────────┘             └───────────────┘
```

**Key Benefits:**
- **Even Distribution:** No single container is overloaded while others sit idle.
- **Auto-Discovery:** Whenever a new container is added via autoscaling, Traefik detects it instantly via the Docker Socket and starts sending traffic.
- **Self-Healing:** If a container fails, Traefik stops sending traffic to it immediately.

---

## 📊 Understanding `API_REPLICAS`

The `API_REPLICAS` variable in your `.env` file controls the **baseline** for your API service.

| Value | Meaning |
| :--- | :--- |
| **API_REPLICAS=2** | Start with 2 containers (Minimum for High Availability) |
| **API_REPLICAS=5** | Start with 5 containers (For expected heavy initial load) |

### Replicas & Autoscaling Logic
Only the `nb-api` service is configured for horizontal scaling.

- **Initial State:** Runs `${API_REPLICAS}` containers (Default: 2).
- **High Load (> 70% CPU):** Autoscaler adds more replicas (Up to **10**).
- **Low Load (< 30% CPU):** Autoscaler removes replicas (Down to **API_REPLICAS**).

> [!NOTE]
> Other services (`nb-worker`, `nb-cron`, `nb-socket`, `nb-redis`, `traefik`) run as **fixed single containers** to preserve resources and maintain state when necessary.

---

## 📈 Production Container Count

Depending on your traffic, the total number of containers in your EC2 instance will change:

| Scenario | API Containers | Total Stack Containers |
| :--- | :--- | :--- |
| **Idle / Normal** | 2 | 7 |
| **Medium Load** | 4 - 6 | 9 - 11 |
| **Peak Traffic** | 10 (Max) | 15 |

---

## 🛠️ Quick Start Deployment

### 1. Environment Setup
```bash
cp .env.template .env
nano .env # Set your DOMAIN, ECR Registry, and API_REPLICAS
```

### 2. Deploy the Stack
```bash
docker swarm init
chmod +x deploy.sh
./deploy.sh
```

### 3. Activate Autoscaling
```bash
chmod +x autoscale.sh
nohup ./autoscale.sh > autoscale.log 2>&1 &
```

---

## ⚙️ Service Catalog

| Service | Expose | Internal Port | Scalable? |
| :--- | :--- | :--- | :--- |
| **traefik** | `80`, `443` | - | ❌ No |
| **nb-api** | `DOMAIN` | `80` | ✅ **Yes (2-10)** |
| **nb-socket** | `socket.DOMAIN` | `9090` | ❌ No |
| **nb-worker** | - | - | ❌ No |
| **nb-cron** | - | - | ❌ No |
| **nb-redis** | - | `6379` | ❌ No |

---

## 🔁 Management Commands

| Action | Command |
| :--- | :--- |
| **Monitor Replicas** | `docker service ls` |
| **View Live Traffic** | `https://traefik.${DOMAIN}` |
| **Check API Health** | `docker service ps nb-stack_nb-api` |
| **Restart Stack** | `./deploy.sh` |

---
*Developed for Nitroberry Production Environments*
