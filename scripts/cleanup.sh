#!/bin/bash

# Kubernetes Cleanup Script for Go Service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-default}"
K8S_DIR="k8s"

echo -e "${YELLOW}Cleaning up Kubernetes resources...${NC}"

# Delete resources
kubectl delete -f ${K8S_DIR}/deployment.yaml -n ${NAMESPACE} --ignore-not-found=true
kubectl delete -f ${K8S_DIR}/service.yaml -n ${NAMESPACE} --ignore-not-found=true

# Optionally delete ingress and namespace
# kubectl delete -f ${K8S_DIR}/ingress.yaml -n ${NAMESPACE} --ignore-not-found=true
# kubectl delete -f ${K8S_DIR}/namespace.yaml --ignore-not-found=true

echo -e "${GREEN}✓ Cleanup completed successfully${NC}"

