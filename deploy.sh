#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
else
  echo "WARNING: .env file not found. Falling back to default system environments."
fi

if [ -z "$CR_REGISTRY" ]; then
  echo "Error: CR_REGISTRY is missing. Please set it in .env"
  exit 1
fi

AWS_REGION=$(echo "$CR_REGISTRY" | cut -d'.' -f4)

echo "AWS ECR Login using region: $AWS_REGION..."
# ECR Authentication (requires IAM role on EC2 OR 'aws configure')
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$CR_REGISTRY"

echo "Deploying Nitroberry to Docker Swarm..."
# Using --with-registry-auth to pass tokens down to all swarm worker nodes securely
# The --prune flag ensures it actively kills any removed services (like metrics/sockets)
docker stack deploy -c docker-compose.yml nitroberry --with-registry-auth --prune

echo "Deployment submitted! Verification:"
docker service ls
