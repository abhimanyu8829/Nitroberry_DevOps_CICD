#!/bin/bash
set -e

# ==============================================================================
# Docker Swarm Deployment Script for Nitroberry
# Handles ECR Authentication & Registry Auth Forwarding to Swarm Nodes
# ==============================================================================

# Ensure CR_REGISTRY is set
if [ -z "$CR_REGISTRY" ]; then
  echo "Error: CR_REGISTRY environment variable is not set."
  echo "Example: export CR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com"
  exit 1
fi

# Extract the AWS region from the CR_REGISTRY variable (assuming standard format)
AWS_REGION=$(echo "$CR_REGISTRY" | cut -d'.' -f4)

echo "Logging into AWS ECR Registry: $CR_REGISTRY in region: $AWS_REGION..."

# 1. Authenticate Docker to AWS ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$CR_REGISTRY"

echo "Deploying the stack to Docker Swarm..."

# 2. Deploy the stack
# The --with-registry-auth flag is CRITICAL. It passes the ECR authentication 
# tokens from the manager node to the worker nodes so they can pull the images.
docker stack deploy -c docker-compose.yml nitroberry --with-registry-auth

echo "Deployment submitted! Check status with: docker stack services nitroberry"
