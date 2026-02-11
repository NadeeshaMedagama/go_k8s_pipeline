#!/bin/bash

# Kubernetes Deployment Script for Go Service
# This script deploys the application to a Kubernetes cluster

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-your-dockerhub-username}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAMESPACE="${NAMESPACE:-default}"
K8S_DIR="k8s"

echo -e "${YELLOW}Starting Kubernetes deployment...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Cannot connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"

# Replace placeholder with actual Docker Hub username
echo -e "${YELLOW}Updating image references...${NC}"
find ${K8S_DIR} -name "*.yaml" -type f -exec sed -i.bak "s/<DOCKERHUB_USERNAME>/${DOCKERHUB_USERNAME}/g" {} \;
find ${K8S_DIR} -name "*.bak" -type f -delete

echo -e "${GREEN}✓ Image references updated${NC}"

# Create namespace if it doesn't exist (optional)
# Uncomment the following lines if you want to use a custom namespace
# echo -e "${YELLOW}Creating namespace...${NC}"
# kubectl apply -f ${K8S_DIR}/namespace.yaml
# NAMESPACE="go-service-app"

# Apply Kubernetes manifests
echo -e "${YELLOW}Applying Kubernetes manifests...${NC}"
kubectl apply -f ${K8S_DIR}/deployment.yaml -n ${NAMESPACE}
kubectl apply -f ${K8S_DIR}/service.yaml -n ${NAMESPACE}

# Optionally apply ingress (uncomment if needed)
# kubectl apply -f ${K8S_DIR}/ingress.yaml -n ${NAMESPACE}

echo -e "${GREEN}✓ Manifests applied successfully${NC}"

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/go-service -n ${NAMESPACE} --timeout=300s

echo -e "${GREEN}✓ Deployment is ready${NC}"

# Get service information
echo -e "${YELLOW}Service Information:${NC}"
kubectl get service go-service -n ${NAMESPACE}

# Get pods
echo -e "${YELLOW}Running Pods:${NC}"
kubectl get pods -l app=go-service -n ${NAMESPACE}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

# Show external IP (if LoadBalancer)
echo -e "${YELLOW}Getting external IP (this may take a moment)...${NC}"
kubectl get service go-service -n ${NAMESPACE} --watch &
sleep 30
killall kubectl 2>/dev/null || true

echo -e "${YELLOW}To check the external IP later, run:${NC}"
echo -e "kubectl get service go-service -n ${NAMESPACE}"

