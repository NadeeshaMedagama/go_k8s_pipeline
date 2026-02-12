# Setup Instructions

Follow these steps to get your Go service deployed with Kubernetes and CI/CD.

## 📋 Prerequisites Checklist

Complete these before starting:

- [ ] Go 1.22+ installed: `go version`
- [ ] Docker installed: `docker --version`
- [ ] kubectl installed: `kubectl version --client`
- [ ] GitHub account with repository
- [ ] Docker Hub account created
- [ ] Kubernetes cluster accessible (Minikube, Docker Desktop, or cloud)

## 🔧 Step-by-Step Setup

### Step 1: Clone and Verify (1 minute)

```bash
# Navigate to the project directory
cd /home/nadeeshame/GolandProjects/go_k8s_pipeline

# Verify all files are present
ls -la

# Test locally
go run main.go &
curl http://localhost:8080
# Should see: Hello from Go + Docker
pkill -f "go run main.go"
```

### Step 2: Docker Hub Configuration (2 minutes)

1. **Create Access Token**:
   - Go to https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Name: "GitHub Actions"
   - Permissions: Read, Write, Delete
   - Click "Generate" and **copy the token**

2. **Create Docker Hub Repository** (optional):
   - Go to https://hub.docker.com/repositories
   - Click "Create Repository"
   - Name: `go-docker-demo`
   - Visibility: Public or Private
   - Click "Create"

### Step 3: GitHub Secrets Configuration (3 minutes)

1. **Go to your GitHub repository**
2. **Click Settings → Secrets and variables → Actions**
3. **Add these secrets**:

   **Required Secrets:**
   
   | Secret Name | Value | How to Get |
   |-------------|-------|------------|
   | `DOCKERHUB_USERNAME` | Your Docker Hub username | hub.docker.com profile |
   | `DOCKERHUB_TOKEN` | Token from Step 2 | Copy from Step 2 |

   **Optional (for automated K8s deployment):**
   
   | Secret Name | Value | How to Get |
   |-------------|-------|------------|
   | `KUBECONFIG` | Base64-encoded kubeconfig | See command below |

4. **Generate KUBECONFIG secret** (optional):
   ```bash
   # Linux
   cat ~/.kube/config | base64 -w 0
   
   # macOS
   cat ~/.kube/config | base64
   
   # Copy the output and paste as KUBECONFIG secret value
   ```

### Step 4: Update Kubernetes Manifests (1 minute)

```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME="your-dockerhub-username"

# Update deployment manifest
sed -i "s/<DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g" k8s/deployment.yaml

# Update kustomization manifest
sed -i "s/<DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g" k8s/kustomization.yaml

# Verify changes
grep "image:" k8s/deployment.yaml
```

### Step 5: Test Docker Build (2 minutes)

```bash
# Build the Docker image locally
docker build -t go-k8s-pipeline:test .

# Run and test
docker run -d -p 8080:8080 --name go-k8s-pipeline-test go-k8s-pipeline:test

# Test the service
curl http://localhost:8080
# Should see: Hello from Go + Docker

# Clean up
docker stop go-k8s-pipeline-test
docker rm go-k8s-pipeline-test
```

### Step 6: Initial Commit and Push (2 minutes)

```bash
# Stage all changes
git add .

# Commit
git commit -m "Configure Kubernetes deployment and CI/CD pipeline"

# Push to trigger CI/CD
git push origin master
```

### Step 7: Verify CI/CD Pipeline (3-5 minutes)

1. **Go to GitHub Actions tab** in your repository
2. **Watch the workflow run**:
   - ✅ Test job should pass
   - ✅ Build and push job should complete
   - ✅ Image should appear on Docker Hub

3. **Verify on Docker Hub**:
   - Go to https://hub.docker.com/r/YOUR-USERNAME/go-docker-demo
   - Should see the `latest` tag

### Step 8: Deploy to Kubernetes (3-5 minutes)

**Option A: Using Deployment Script (Easiest)**

```bash
# Verify kubectl is configured
kubectl cluster-info

# Run deployment script
./scripts/deploy.sh

# Wait for deployment to complete (script does this automatically)
```

**Option B: Manual Deployment**

```bash
# Apply manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Wait for rollout
kubectl rollout status deployment/go-service

# Check status
kubectl get pods -l app=go-service
kubectl get service go-service
```

**Option C: Using GitHub Actions**

1. Go to **Actions** tab
2. Click **Run workflow**
3. Configure:
   - Branch: `main`
   - Environment: `production`
   - Deploy to Kubernetes: `true`
4. Click **Run workflow**
5. Monitor progress in Actions tab

### Step 9: Access the Application (1 minute)

**Local/Development (Port Forward):**

```bash
# Forward port to local machine
kubectl port-forward service/go-service 8080:80

# In another terminal, test
curl http://localhost:8080
# Should see: Hello from Go + Docker
```

**Cloud/Production (LoadBalancer):**

```bash
# Get external IP (may take a few minutes)
kubectl get service go-service --watch

# Once EXTERNAL-IP is available (not <pending>), test
curl http://<EXTERNAL-IP>
```

### Step 10: Verify Everything Works (2 minutes)

```bash
# Check deployment
kubectl get deployment go-service
# Should show: READY 3/3

# Check pods
kubectl get pods -l app=go-service
# Should show: 3 pods in Running state with READY 1/1

# Check service
kubectl get service go-service
# Should show: LoadBalancer with EXTERNAL-IP or <pending>

# View logs
kubectl logs -l app=go-service --tail=20

# Test the endpoint
curl http://localhost:8080  # if using port-forward
# OR
curl http://<EXTERNAL-IP>   # if using LoadBalancer
```

## ✅ Success Criteria

Your setup is complete when:

- ✅ GitHub Actions workflow runs successfully
- ✅ Docker image appears on Docker Hub
- ✅ All 3 pods are Running and Ready
- ✅ Service has been created
- ✅ Application responds with "Hello from Go + Docker"

## 🎯 What You've Accomplished

- ✅ Local Go development environment
- ✅ Docker containerization
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Automated Docker image builds
- ✅ Kubernetes deployment with 3 replicas
- ✅ LoadBalancer service configuration
- ✅ Manual and automated deployment options

## 📚 Next Steps

Now that your setup is complete:

1. **Read the documentation**:
   - [QUICKSTART.md](QUICKSTART.md) - Quick reference guide
   - [KUBERNETES.md](KUBERNETES.md) - Advanced Kubernetes features
   - [CICD_SETUP.md](CICD_SETUP.md) - CI/CD pipeline details

2. **Explore features**:
   - Scale the deployment: `kubectl scale deployment/go-service --replicas=5`
   - View logs: `kubectl logs -l app=go-service -f`
   - Update the app: Modify `main.go`, commit, and push

3. **Production enhancements**:
   - Configure ingress for domain access
   - Add SSL/TLS certificates
   - Set up monitoring and alerting
   - Implement auto-scaling

## 🆘 Troubleshooting

### GitHub Actions failing?
- Verify secrets are set correctly
- Check Actions tab for detailed error logs
- See [CICD_SETUP.md](CICD_SETUP.md) troubleshooting section

### Pods not starting?
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Can't access service?
```bash
# Use port-forward as fallback
kubectl port-forward service/go-service 8080:80
curl http://localhost:8080
```

### Image pull errors?
- Verify Docker Hub username in k8s/deployment.yaml
- Check image exists: `docker pull YOUR-USERNAME/go-docker-demo:latest`
- See [KUBERNETES.md](KUBERNETES.md) for image pull secret setup

## 📞 Getting Help

If you're stuck:

1. Check the specific documentation file for your issue
2. Review error messages carefully
3. Use `kubectl describe` and `kubectl logs` for debugging
4. Check GitHub Actions logs for CI/CD issues
5. Refer to [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for overview

## ⏱️ Total Setup Time

- **Estimated**: 20-25 minutes
- **Prerequisites**: 5 minutes
- **Configuration**: 10 minutes
- **Deployment**: 5-10 minutes

## 🎉 Congratulations!

You've successfully set up a production-ready Go service with complete CI/CD and Kubernetes deployment!

---

**Need help?** Open an issue in the repository or check the documentation files.

