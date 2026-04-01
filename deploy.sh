#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "Creating overlay networks..."
docker network create --driver overlay public 2>/dev/null || true
docker network create --driver overlay private 2>/dev/null || true

echo "Deploying the stack..."
docker stack deploy -c docker-compose.yml nb-stack

echo "------------------------------------------------"
echo "Deployment successful!"
echo "Public IP: $PUBLIC_IP"
echo ""
echo "Access URLs:"
echo "  API: http://$PUBLIC_IP/"
echo "  Traefik Dashboard: http://$PUBLIC_IP:8080"
echo "  Prometheus: http://$PUBLIC_IP:9090"
echo "  Grafana: http://$PUBLIC_IP:3000 (admin/admin)"
echo ""
echo "Check services:"
docker stack services nb-stack

echo ""
echo "Check API containers (should show 4 replicas):"
docker service ps nb-stack_nb-api