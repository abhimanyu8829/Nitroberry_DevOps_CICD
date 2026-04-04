#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "Creating overlay networks..."
docker network create --driver overlay nb_network 2>/dev/null || true
docker network create --driver overlay monitoring 2>/dev/null || true

echo "Setting permissions..."
chmod +x autoscale.sh 2>/dev/null || true

echo "Deploying the stack..."
docker stack deploy -c docker-compose.yml nb-stack

echo "------------------------------------------------"
echo "✅ Deployment successful!"
echo ""
echo "Access URLs:"
echo "  API: https://${DOMAIN}"
echo "  Socket: wss://socket.${DOMAIN}"
echo "  Traefik Dashboard: https://traefik.${DOMAIN}"
echo "  Grafana: https://grafana.${DOMAIN}"
echo ""
echo "Check services:"
docker stack services nb-stack

echo ""
echo "Check API replicas:"
docker service ps nb-stack_nb-api