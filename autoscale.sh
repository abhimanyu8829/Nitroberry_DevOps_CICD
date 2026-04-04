#!/bin/bash

STACK_NAME="nb-stack"
SERVICE_NAME="nb-stack_nb-api"
MIN_REPLICAS=2
MAX_REPLICAS=10
TARGET_CPU=70
CHECK_INTERVAL=30

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  PRODUCTION AUTOSCALING MONITOR${NC}"
echo -e "${YELLOW}  Stack: $STACK_NAME${NC}"
echo -e "${YELLOW}  Service: $SERVICE_NAME${NC}"
echo -e "${YELLOW}  Min: $MIN_REPLICAS | Max: $MAX_REPLICAS | Target CPU: ${TARGET_CPU}%${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

while true; do
    CONTAINERS=$(docker ps -q --filter name=nb-stack_nb-api 2>/dev/null)
    
    if [ -n "$CONTAINERS" ]; then
        CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINERS 2>/dev/null | sed 's/%//g' | awk '{sum+=$1} END {if(NR>0) print sum/NR; else print 0}')
        if [ -z "$CPU_USAGE" ]; then CPU_USAGE=0; fi
        CPU_INT=$(printf "%.0f" "$CPU_USAGE")
        CURRENT_REPLICAS=$(echo "$CONTAINERS" | wc -l)
        
        if [ $CPU_INT -gt $TARGET_CPU ]; then COLOR=$RED
        elif [ $CPU_INT -gt 50 ]; then COLOR=$YELLOW
        else COLOR=$GREEN; fi
        
        echo -e "[$(date '+%H:%M:%S')] CPU: ${COLOR}${CPU_INT}%${NC} | Replicas: $CURRENT_REPLICAS"
        
        if [ $CPU_INT -gt $TARGET_CPU ] && [ $CURRENT_REPLICAS -lt $MAX_REPLICAS ]; then
            NEW=$((CURRENT_REPLICAS + 1))
            echo -e "${RED}??  HIGH CPU DETECTED! Scaling UP to $NEW replicas${NC}"
            docker service scale "$SERVICE_NAME=$NEW"
            echo -e "${GREEN}? Scaled up successfully. Waiting 60 seconds...${NC}"
            sleep 60
        elif [ $CPU_INT -lt 30 ] && [ $CURRENT_REPLICAS -gt $MIN_REPLICAS ]; then
            NEW=$((CURRENT_REPLICAS - 1))
            echo -e "${YELLOW}?? LOW CPU DETECTED! Scaling DOWN to $NEW replicas${NC}"
            docker service scale "$SERVICE_NAME=$NEW"
            echo -e "${GREEN}? Scaled down successfully. Waiting 60 seconds...${NC}"
            sleep 60
        fi
    else
        echo -e "[$(date '+%H:%M:%S')] ${RED}No API containers found. Stack may not be deployed.${NC}"
    fi
    sleep $CHECK_INTERVAL
done
