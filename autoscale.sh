
#!/bin/bash
# ==============================================================================
# Docker Swarm Autoscaler for 'nb-api'
# Run this script as a cron job on the Swarm Manager node every minute:
# * * * * * /path/to/autoscale.sh >> /var/log/swarm-autoscale.log 2>&1
# ==============================================================================

SERVICE_NAME="nitroberry_nb-api"
MIN_REPLICAS=4
MAX_REPLICAS=10
PROMETHEUS_URL="http://127.0.0.1:9090" # Change if querying from a different node

# Thresholds in %
SCALE_UP_THRESHOLD=75
SCALE_DOWN_THRESHOLD=30

echo "[$(date -u)] Checking auto-scaling for $SERVICE_NAME..."

# Step 1: Query Prometheus for average CPU usage of the service over the last 1m
# This query calculates the sum of CPU rates across the service replicas divided by the number of replicas
PROQL_QUERY="avg(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=\"$SERVICE_NAME\"}[1m])) * 100"

# Note: jq is required
RESPONSE=$(curl -s -G --data-urlencode "query=$PROQL_QUERY" "$PROMETHEUS_URL/api/v1/query")
STATUS=$(echo "$RESPONSE" | jq -r '.status')

if [ "$STATUS" != "success" ]; then
  echo "Error querying Prometheus. Exiting."
  exit 1
fi

CPU_USAGE=$(echo "$RESPONSE" | jq -r '.data.result[0].value[1]')

if [ "$CPU_USAGE" == "null" ] || [ -z "$CPU_USAGE" ]; then
  echo "No CPU data found for $SERVICE_NAME."
  exit 1
fi

# Convert string float to integer for bash comparison
CPU_INT=$(printf %.0f "$CPU_USAGE")
echo "Current Average CPU Usage: ${CPU_INT}%"

# Step 2: Get current replicas
CURRENT_REPLICAS=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.Mode.Replicated.Replicas}}')
echo "Current Replicas: $CURRENT_REPLICAS"

# Step 3: Determine scaling action
if [ "$CPU_INT" -gt "$SCALE_UP_THRESHOLD" ]; then
  if [ "$CURRENT_REPLICAS" -lt "$MAX_REPLICAS" ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS + 1))
    echo "High CPU detected! Scaling UP to $NEW_REPLICAS replicas..."
    docker service update --replicas "$NEW_REPLICAS" "$SERVICE_NAME"
  else
    echo "High CPU but already at max capacity ($MAX_REPLICAS replicas)."
  fi
elif [ "$CPU_INT" -lt "$SCALE_DOWN_THRESHOLD" ]; then
  if [ "$CURRENT_REPLICAS" -gt "$MIN_REPLICAS" ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS - 1))
    echo "Low CPU detected. Scaling DOWN to $NEW_REPLICAS replicas..."
    docker service update --replicas "$NEW_REPLICAS" "$SERVICE_NAME"
  else
    echo "Low CPU but already at minimum capacity ($MIN_REPLICAS replicas)."
  fi
else
  echo "CPU usage is within acceptable range. No scaling action required."
fi
