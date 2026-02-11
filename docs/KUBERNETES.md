# Kubernetes Deployment Quick Start Guide

This guide will help you quickly deploy the Go service to a Kubernetes cluster.

## Prerequisites Checklist

- [ ] Docker installed and running
- [ ] kubectl installed
- [ ] Access to a Kubernetes cluster
- [ ] Docker Hub account (for pulling images)

## Step-by-Step Deployment

### 1. Verify Kubernetes Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Configure Docker Hub Username

Edit the Kubernetes manifests and replace `<DOCKERHUB_USERNAME>` with your actual Docker Hub username:

```bash
# Option A: Using sed (Linux/Mac)
export DOCKERHUB_USERNAME="your-username"
sed -i "s/<DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g" k8s/deployment.yaml
sed -i "s/<DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g" k8s/kustomization.yaml

# Option B: Manual edit
# Edit k8s/deployment.yaml and k8s/kustomization.yaml manually
```

### 3. Deploy the Application

```bash
# Deploy to default namespace
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 4. Verify Deployment

```bash
# Check deployment status
kubectl get deployments

# Check pods
kubectl get pods -l app=go-service

# Check service
kubectl get service go-service

# View logs
kubectl logs -l app=go-service
```

### 5. Access the Application

#### Option A: LoadBalancer (Cloud providers)

```bash
# Wait for external IP
kubectl get service go-service --watch

# Once EXTERNAL-IP is available, test it
curl http://<EXTERNAL-IP>
```

#### Option B: Port Forwarding (Local/Development)

```bash
# Forward port 8080 to the service
kubectl port-forward service/go-service 8080:80

# In another terminal, test the application
curl http://localhost:8080
```

#### Option C: NodePort (Alternative)

```bash
# Change service type to NodePort
kubectl patch service go-service -p '{"spec":{"type":"NodePort"}}'

# Get the NodePort
kubectl get service go-service

# Access using any node IP
curl http://<NODE-IP>:<NODE-PORT>
```

## Common Operations

### Scale the Application

```bash
# Scale to 5 replicas
kubectl scale deployment/go-service --replicas=5

# Verify scaling
kubectl get pods -l app=go-service
```

### Update the Application

```bash
# Update to a new image version
kubectl set image deployment/go-service go-service=<dockerhub-username>/go-docker-demo:v2.0

# Watch rollout
kubectl rollout status deployment/go-service
```

### View Logs

```bash
# All pods
kubectl logs -l app=go-service --tail=100 -f

# Specific pod
kubectl logs <pod-name> -f
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/go-service

# Check rollout history
kubectl rollout history deployment/go-service

# Rollback to specific revision
kubectl rollout undo deployment/go-service --to-revision=2
```

### Delete the Application

```bash
# Delete all resources
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml

# Or use the cleanup script
./scripts/cleanup.sh
```

## Troubleshooting

### Pods not starting?

```bash
# Describe pod to see events
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>

# Check resource usage
kubectl top pods
```

### Can't pull image?

```bash
# Create a Docker Hub secret
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email>

# Update deployment to use the secret
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "dockerhub-secret"}]}'
```

### Service not accessible?

```bash
# Check service endpoints
kubectl get endpoints go-service

# Check if pods are ready
kubectl get pods -l app=go-service

# Test connectivity from inside the cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://go-service
```

### Check cluster events

```bash
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

## Using Deployment Scripts

The project includes helper scripts for common operations:

### Deploy
```bash
export DOCKERHUB_USERNAME="your-username"
./scripts/deploy.sh
```

### Rollback
```bash
./scripts/rollback.sh
```

### Cleanup
```bash
./scripts/cleanup.sh
```

## Next Steps

- Set up monitoring with Prometheus
- Configure auto-scaling with HPA
- Add ingress for external access
- Implement CI/CD pipeline
- Add health checks and readiness probes
- Configure resource limits and requests
- Set up logging with ELK or similar

## Useful Commands Reference

```bash
# Get all resources
kubectl get all -l app=go-service

# Watch pod status
kubectl get pods -l app=go-service --watch

# Exec into a pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward to a specific pod
kubectl port-forward <pod-name> 8080:8080

# Get deployment YAML
kubectl get deployment go-service -o yaml

# Edit deployment live
kubectl edit deployment go-service
```

## Support

If you encounter issues, check:
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- Project README.md for detailed information

