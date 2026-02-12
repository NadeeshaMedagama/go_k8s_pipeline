# Quick Start Guide

Get your Go service up and running in 5 minutes!

## 🚀 Option 1: Local Development (Fastest)

```bash
# Clone the repository
git clone <your-repo-url>
cd go_k8s_pipeline

# Run the application
go run main.go

# Test it (in another terminal)
curl http://localhost:8080
# Expected: Hello from Go + Docker
```

## 🐳 Option 2: Docker (Recommended)

```bash
# Build the Docker image
docker build -t go-service:local .

# Run the container
docker run -d -p 8080:8080 --name go-service go-service:local

# Test it
curl http://localhost:8080
# Expected: Hello from Go + Docker

# View logs
docker logs go-service -f

# Stop and remove
docker stop go-service && docker rm go-service
```

## ☸️ Option 3: Kubernetes (Production)

### Prerequisites
- Kubernetes cluster running (Minikube, Docker Desktop, or cloud)
- kubectl configured
- Docker Hub account

### Deploy in 3 Steps

**Step 1: Update configuration**
```bash
# Replace with your Docker Hub username
export DOCKERHUB_USERNAME="your-username"
sed -i "s/<DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g" k8s/deployment.yaml
```

**Step 2: Deploy**
```bash
# Deploy using the script
./scripts/deploy.sh

# Or deploy manually
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

**Step 3: Access**
```bash
# For local development (port forwarding)
kubectl port-forward service/go-service 8080:80

# Test it (in another terminal)
curl http://localhost:8080

# For cloud (LoadBalancer)
kubectl get service go-service
# Wait for EXTERNAL-IP, then:
curl http://<EXTERNAL-IP>
```

## 🔄 CI/CD Pipeline Setup

### Step 1: Configure GitHub Secrets

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Add these secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: [Create token here](https://hub.docker.com/settings/security)

### Step 2: Trigger Pipeline

**Automatic deployment**: Just push to master
```bash
git add .
git commit -m "Initial deployment"
git push origin master
# This will automatically:
# 1. Run tests
# 2. Build and push Docker image
# 3. Deploy to Kubernetes (production)
```

**Manual deployment with environment selection**:
1. Go to GitHub Actions tab
2. Click "Run workflow"
3. Select branch: `main`
4. Environment: Choose `staging` or `production`
5. Deploy to Kubernetes: `true`
6. Click "Run workflow"

## 📊 Verify Deployment

### Local/Docker
```bash
curl http://localhost:8080
# Should see: Hello from Go + Docker
```

### Kubernetes
```bash
# Check pods
kubectl get pods -l app=go-service

# Check logs
kubectl logs -l app=go-service

# Test service
kubectl port-forward service/go-service 8080:80
curl http://localhost:8080
```

## 🆘 Troubleshooting

### Local: Port already in use
```bash
# Find and kill the process using port 8080
lsof -ti:8080 | xargs kill -9
```

### Docker: Container won't start
```bash
# Check logs
docker logs go-k8s-pipeline

# Rebuild image
docker build --no-cache -t go-k8s-pipeline:local .
```

### Kubernetes: Pods not starting
```bash
# Describe pod to see error
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check if image exists on Docker Hub
docker pull <dockerhub-username>/go-docker-demo:latest
```

### Kubernetes: Can't access service
```bash
# Check service endpoints
kubectl get endpoints go-service

# If no endpoints, pods may not be ready
kubectl get pods -l app=go-service

# Use port-forward as fallback
kubectl port-forward service/go-service 8080:80
```

## 📚 Next Steps

- Read [README.md](../README.md) for complete documentation
- Check [KUBERNETES.md](KUBERNETES.md) for advanced Kubernetes features
- Review [CICD_SETUP.md](CICD_SETUP.md) for CI/CD details
- Use [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) for production deployments

## 🎯 Common Commands

```bash
# Development
go test ./...                              # Run tests
go build                                   # Build binary
docker build -t go-k8s-pipeline .          # Build image

# Kubernetes
kubectl get all -l app=go-service          # Get all resources
kubectl logs -l app=go-service -f          # Stream logs
kubectl scale deployment go-service --replicas=5  # Scale
./scripts/rollback.sh                      # Rollback
./scripts/cleanup.sh                       # Clean up

# CI/CD
git push origin master                       # Trigger pipeline
gh workflow run "Go CI/CD Pipeline"        # Manual trigger
```

## 🎊 Success!

If you see "Hello from Go + Docker", your deployment is working! 🎉

For production deployments, refer to the detailed documentation files.

