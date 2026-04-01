#!/bin/bash
# Simple auto-scaling for nb-api based on CPU

SERVICE_NAME="nb-stack_nb-api"
MIN_REPLICAS=4
MAX_REPLICAS=10
SCALE_UP_THRESHOLD=70
SCALE_DOWN_THRESHOLD=30

echo "[$(date)] Checking CPU..."

# Get CPU usage from docker stats
CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" $(docker ps -q --filter name=nb-stack_nb-api) | sed 's/%//g' | awk '{sum+=$1} END {print sum/NR}')

if [ -z "$CPU_USAGE" ]; then
  CPU_USAGE=0
fi

CPU_INT=$(printf %.0f "$CPU_USAGE")
CURRENT_REPLICAS=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.Mode.Replicated.Replicas}}')

echo "  CPU: ${CPU_INT}% | Replicas: $CURRENT_REPLICAS"

# Scale logic
if [ "$CPU_INT" -gt "$SCALE_UP_THRESHOLD" ] && [ "$CURRENT_REPLICAS" -lt "$MAX_REPLICAS" ]; then
  NEW=$((CURRENT_REPLICAS + 1))
  echo "  🔵 SCALING UP to $NEW replicas"
  docker service scale "$SERVICE_NAME=$NEW"
elif [ "$CPU_INT" -lt "$SCALE_DOWN_THRESHOLD" ] && [ "$CURRENT_REPLICAS" -gt "$MIN_REPLICAS" ]; then
  NEW=$((CURRENT_REPLICAS - 1))
  echo "  🟢 SCALING DOWN to $NEW replicas"
  docker service scale "$SERVICE_NAME=$NEW"
else
  echo "  ✅ No scaling needed"
fi