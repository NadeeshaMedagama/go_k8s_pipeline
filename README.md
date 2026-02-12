# Go K8s Pipeline

A lightweight Go web service with a complete CI/CD pipeline for automated Docker image building and Kubernetes deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Local Development](#local-development)
  - [Docker](#docker)
- [CI/CD Pipeline](#cicd-pipeline)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 📚 Additional Documentation

- **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes! ⚡
- **[Kubernetes Deployment Guide](docs/KUBERNETES.md)** - Detailed Kubernetes deployment instructions
- **[CI/CD Setup Guide](docs/CICD_SETUP.md)** - Complete CI/CD pipeline configuration and usage
- **[Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment verification checklist

## 🎯 Overview

This project demonstrates a production-ready Go web service with automated CI/CD workflows. It showcases modern DevOps practices including containerization with Docker, multi-stage builds for optimized image sizes, and GitHub Actions for continuous integration and deployment.

The service provides a simple HTTP server that responds with a greeting message, serving as a foundation for more complex microservices.

## ✨ Features

- **Lightweight HTTP Server**: Built with Go's standard `net/http` package
- **Docker Support**: Multi-stage Dockerfile for minimal image size
- **CI/CD Automation**: GitHub Actions workflow for automated testing and deployment
- **Container Registry Integration**: Automatic Docker Hub image publishing
- **Production Ready**: Follows Go and Docker best practices

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Go**: Version 1.22 or higher ([Download](https://golang.org/dl/))
- **Docker**: Latest version ([Download](https://www.docker.com/get-started))
- **Git**: For version control

## 🚀 Getting Started

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd go_k8s_pipeline
   ```

2. **Install dependencies**
   ```bash
   go mod download
   ```

3. **Run the application**
   ```bash
   go run main.go
   ```

4. **Test the service**
   ```bash
   curl http://localhost:8080
   ```
   
   Expected response:
   ```
   Hello from Go + Docker
   ```

### Docker

#### Build the Docker image locally

```bash
docker build -t go-k8s-pipeline:local .
```

#### Run the container

```bash
docker run -p 8080:8080 go-k8s-pipeline:local
```

The service will be available at `http://localhost:8080`

#### Stop the container

```bash
docker stop $(docker ps -q --filter ancestor=go-k8s-pipeline:local)
```

## 🔄 CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment. The pipeline supports multiple trigger methods and can automatically deploy to Kubernetes clusters.

### Trigger Methods

#### 1. Automatic Triggers
- **Push to master**: Automatically runs tests, builds Docker image, and **deploys to Kubernetes** on every push to the `master` branch
- **Pull Requests**: Automatically runs tests on pull requests targeting the `master` branch (no deployment)

#### 2. Manual Trigger (workflow_dispatch)
To manually trigger the workflow:

1. Go to your repository on GitHub
2. Click on the **Actions** tab
3. Select the **Go CI/CD Pipeline** workflow from the left sidebar
4. Click the **Run workflow** dropdown button
5. Configure the workflow:
   - **Branch**: Select the branch to run the workflow on (default: `master`)
   - **Environment**: Choose `staging` or `production`
   - **Deploy to Kubernetes**: Toggle `true` to deploy to your K8s cluster
6. Click **Run workflow**

### Pipeline Jobs

#### 1. **Test Job**
- Checks out the code
- Sets up Go 1.22 environment
- Caches Go modules for faster builds
- Runs tests with race detection and coverage
- Generates and uploads coverage reports

#### 2. **Build and Push Job**
- Runs only on pushes to master or manual triggers
- Builds Docker image with BuildKit
- Pushes to Docker Hub with multiple tags:
  - `latest` (for master branch)
  - Branch name
  - Commit SHA
- Uses layer caching for faster builds

#### 3. **Deploy to Kubernetes Job**
- Runs automatically on pushes to master branch
- Can also be manually triggered with `deploy_to_k8s=true`
- Configures kubectl with your cluster credentials
- Updates Kubernetes manifests with correct image tags
- Applies deployment and service manifests
- Waits for deployment rollout to complete
- Reports deployment status
- Supports both automatic (production) and manual (staging/production) deployments

### Required Secrets

Configure the following secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Docker image push |
| `DOCKERHUB_TOKEN` | Docker Hub access token ([Create one](https://hub.docker.com/settings/security)) | Docker image push |
| `KUBECONFIG` | Base64-encoded kubeconfig file | Kubernetes deployment |

#### Setting up KUBECONFIG Secret

```bash
# Encode your kubeconfig file
cat ~/.kube/config | base64 -w 0

# Copy the output and add it as KUBECONFIG secret in GitHub
```

### Workflow File

The CI/CD workflow is defined in `.github/workflows/ci-cd.yml`

## 📁 Project Structure

```
go_k8s_pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # CI/CD pipeline configuration
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # Deployment configuration
│   ├── service.yaml            # Service configuration
│   ├── ingress.yaml            # Ingress configuration (optional)
│   ├── namespace.yaml          # Namespace configuration (optional)
│   └── kustomization.yaml      # Kustomize configuration
├── scripts/                    # Deployment scripts
│   ├── deploy.sh               # Kubernetes deployment script
│   ├── rollback.sh             # Rollback script
│   └── cleanup.sh              # Cleanup script
├── main.go                     # Main application entry point
├── go.mod                      # Go module dependencies
├── Dockerfile                  # Multi-stage Docker build
└── README.md                   # Project documentation
```

## 🔌 API Endpoints

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | `/` | Health check and greeting | `Hello from Go + Docker` |

## ⚙️ Configuration

### Application Configuration

The service runs on port `8080` by default. To change the port, modify the `main.go` file:

```go
log.Fatal(http.ListenAndServe(":YOUR_PORT", nil))
```

### Docker Configuration

The Dockerfile uses a multi-stage build:
- **Builder Stage**: Uses `golang:1.25-alpine` for compiling
- **Runtime Stage**: Uses `alpine:latest` for minimal footprint

## 🌐 Deployment

### Kubernetes Deployment (Recommended)

#### Prerequisites
- A running Kubernetes cluster (local: Minikube, Kind, Docker Desktop, or cloud: GKE, EKS, AKS)
- `kubectl` installed and configured
- Docker Hub account with the published image

#### Quick Deploy

**Option 1: Using the deployment script**

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME="your-dockerhub-username"

# Run the deployment script
./scripts/deploy.sh
```

**Option 2: Using kubectl directly**

```bash
# Update the deployment manifest with your Docker Hub username
sed -i "s/<DOCKERHUB_USERNAME>/your-dockerhub-username/g" k8s/deployment.yaml

# Apply the manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl rollout status deployment/go-service

# Get service information
kubectl get service go-service
```

**Option 3: Using Kustomize**

```bash
# Update kustomization.yaml with your Docker Hub username
cd k8s
kustomize edit set image your-dockerhub-username/go-docker-demo:latest

# Apply with kustomize
kubectl apply -k .
```

#### Accessing the Application

**For LoadBalancer Service:**
```bash
# Get the external IP
kubectl get service go-service

# Access the application
curl http://<EXTERNAL-IP>
```

**For local development (port-forward):**
```bash
# Forward local port to the service
kubectl port-forward service/go-service 8080:80

# Access the application
curl http://localhost:8080
```

#### Advanced Deployment Options

**Using Ingress (Optional)**

If you have an ingress controller installed:

```bash
# Update ingress.yaml with your domain
sed -i "s/go-service.example.com/your-domain.com/g" k8s/ingress.yaml

# Apply ingress
kubectl apply -f k8s/ingress.yaml

# Access via domain
curl http://your-domain.com
```

**Using Custom Namespace**

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy to custom namespace
export NAMESPACE="go-service-app"
kubectl apply -f k8s/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/service.yaml -n $NAMESPACE
```

#### Scaling the Deployment

```bash
# Scale up to 5 replicas
kubectl scale deployment/go-service --replicas=5

# Auto-scale based on CPU
kubectl autoscale deployment/go-service --min=3 --max=10 --cpu-percent=80
```

#### Monitoring and Troubleshooting

```bash
# Check pods status
kubectl get pods -l app=go-service

# View pod logs
kubectl logs -l app=go-service --tail=100 -f

# Describe deployment
kubectl describe deployment go-service

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### Rollback

If something goes wrong:

```bash
# Using the rollback script
./scripts/rollback.sh

# Or manually
kubectl rollout undo deployment/go-service

# Check rollback status
kubectl rollout status deployment/go-service
```

#### Cleanup

To remove all resources:

```bash
# Using the cleanup script
./scripts/cleanup.sh

# Or manually
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml
```

### Manual Docker Deployment

Pull and run the latest image from Docker Hub:

```bash
docker pull <your-dockerhub-username>/go-docker-demo:latest
docker run -d -p 8080:8080 <your-dockerhub-username>/go-docker-demo:latest
```

### CI/CD Automated Deployment

The GitHub Actions workflow can automatically deploy to Kubernetes:

1. Configure the `KUBECONFIG` secret in GitHub
2. Manually trigger the workflow with `deploy_to_k8s=true`
3. The pipeline will automatically:
   - Build and push the Docker image
   - Update Kubernetes manifests
   - Deploy to your cluster
   - Wait for rollout completion
   - Report deployment status

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open-source and available under the [MIT License](LICENSE).

---


## 📧 Contact

For questions or support, please open an issue in the repository.

---

## 🚀 Quick Reference

### Common Commands

```bash
# Local Development
go run main.go                          # Run locally
go test ./...                           # Run tests
docker build -t go-k8s-pipeline .       # Build image
docker run -p 8080:8080 go-k8s-pipeline # Run container

# Kubernetes Deployment
./scripts/deploy.sh                     # Deploy to K8s
kubectl get pods -l app=go-service      # Check pods
kubectl logs -l app=go-service -f       # View logs
kubectl port-forward svc/go-service 8080:80  # Port forward
./scripts/rollback.sh                   # Rollback deployment
./scripts/cleanup.sh                    # Clean up resources

# CI/CD
git push origin master                    # Trigger pipeline
gh workflow run "Go CI/CD Pipeline"     # Manual trigger (GitHub CLI)
```

### Key Files

| File | Description |
|------|-------------|
| `main.go` | Application entry point |
| `Dockerfile` | Container image definition |
| `.github/workflows/ci-cd.yml` | CI/CD pipeline configuration |
| `k8s/deployment.yaml` | Kubernetes deployment manifest |
| `k8s/service.yaml` | Kubernetes service manifest |
| `scripts/deploy.sh` | Deployment automation script |

### Documentation Index

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Main project documentation |
| [QUICKSTART.md](docs/QUICKSTART.md) | Get started in 5 minutes |
| [KUBERNETES.md](docs/KUBERNETES.md) | Kubernetes deployment guide |
| [CICD_SETUP.md](docs/CICD_SETUP.md) | CI/CD pipeline setup and usage |
| [DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md) | Deployment verification checklist |

### Useful Links

- [Go Documentation](https://golang.org/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Hub](https://hub.docker.com/)

---

**Built with ❤️ using Go and Docker**

