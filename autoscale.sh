#!/bin/bash
# ==============================================================================
# Prometheus Metric-based Autoscaler for nb-api Swarm Service
# Setup as a Cron Job on Swarm Manager (* * * * * /path/to/autoscale.sh)
# ==============================================================================

SERVICE_NAME="nitroberry_nb-api"
MIN_REPLICAS=4
MAX_REPLICAS=10
PROMETHEUS_URL="http://127.0.0.1:9090" # TODO: Configure if prometheus is remote

SCALE_UP_THRESHOLD=75 # Percentage
SCALE_DOWN_THRESHOLD=30 # Percentage

# Query calculating the average CPU rate of the nb-api containers
PROQL_QUERY="avg(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name=\"$SERVICE_NAME\"}[1m])) * 100"

RESPONSE=$(curl -s -G --data-urlencode "query=$PROQL_QUERY" "$PROMETHEUS_URL/api/v1/query")

# Extract the float metric from Prometheus jq extraction
CPU_USAGE=$(echo "$RESPONSE" | grep -o '"value":\[[^,]*,"[^"]*"' | cut -d'"' -f6 || true)

if [ -z "$CPU_USAGE" ]; then
  echo "Prometheus CPU metrics unavailable for $SERVICE_NAME."
  exit 1
fi

# Convert string float to integer
CPU_INT=$(printf %.0f "$CPU_USAGE")
CURRENT_REPLICAS=$(docker service inspect "$SERVICE_NAME" --format '{{.Spec.Mode.Replicated.Replicas}}')

echo "API Average CPU: ${CPU_INT}% (Current Replicas: $CURRENT_REPLICAS)"

# Autoscaling Logic
if [ "$CPU_INT" -gt "$SCALE_UP_THRESHOLD" ]; then
  if [ "$CURRENT_REPLICAS" -lt "$MAX_REPLICAS" ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS + 1))
    echo "Scaling UP to $NEW_REPLICAS..."
    docker service scale "${SERVICE_NAME}=${NEW_REPLICAS}"
  fi
elif [ "$CPU_INT" -lt "$SCALE_DOWN_THRESHOLD" ]; then
  if [ "$CURRENT_REPLICAS" -gt "$MIN_REPLICAS" ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS - 1))
    echo "Scaling DOWN to $NEW_REPLICAS..."
    docker service scale "${SERVICE_NAME}=${NEW_REPLICAS}"
  fi
fi
