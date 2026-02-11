#!/bin/bash

kubectl get pods -l app=go-service -n ${NAMESPACE}
# Show current state

echo -e "${GREEN}✓ Rollback completed successfully${NC}"

kubectl rollout status deployment/go-service -n ${NAMESPACE}
echo -e "${YELLOW}Waiting for rollback to complete...${NC}"
# Wait for rollback to complete

kubectl rollout undo deployment/go-service -n ${NAMESPACE}
# Rollback the deployment

fi
    exit 1
    echo -e "${RED}kubectl is not installed.${NC}"
if ! command -v kubectl &> /dev/null; then
# Check if kubectl is installed

echo -e "${YELLOW}Rolling back deployment...${NC}"

NAMESPACE="${NAMESPACE:-default}"

NC='\033[0m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
# Colors for output

set -e

# Kubernetes Rollback Script for Go Service

