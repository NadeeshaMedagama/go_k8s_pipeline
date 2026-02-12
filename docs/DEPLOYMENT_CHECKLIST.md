# Deployment Checklist

Use this checklist to ensure a smooth deployment of the Go service.

## Pre-Deployment Checklist

### Docker Hub Setup
- [ ] Docker Hub account created
- [ ] Repository `go-docker-demo` created (or will be auto-created)
- [ ] Access token generated with Read/Write permissions
- [ ] Token saved securely

### Kubernetes Cluster
- [ ] Kubernetes cluster is running and accessible
- [ ] `kubectl` is installed and configured
- [ ] Current context is set to correct cluster: `kubectl config current-context`
- [ ] You have necessary permissions (create deployments, services)
- [ ] Cluster has sufficient resources (CPU, memory)

### GitHub Repository
- [ ] Code pushed to GitHub repository
- [ ] GitHub Secrets configured:
  - [ ] `DOCKERHUB_USERNAME`
  - [ ] `DOCKERHUB_TOKEN`
  - [ ] `KUBECONFIG` (if using automated K8s deployment)

### Local Environment
- [ ] Go 1.22+ installed
- [ ] Docker installed and running
- [ ] kubectl installed
- [ ] Scripts have execute permissions: `chmod +x scripts/*.sh`

## Deployment Checklist

### Step 1: Test Locally
- [ ] Run tests: `go test ./...`
- [ ] Build locally: `go build`
- [ ] Test locally: `go run main.go` then `curl http://localhost:8080`

### Step 2: Build Docker Image
- [ ] Build image: `docker build -t go-k8s-pipeline:test .`
- [ ] Test image: `docker run -p 8080:8080 go-k8s-pipeline:test`
- [ ] Verify: `curl http://localhost:8080`
- [ ] Stop container: `docker stop $(docker ps -q --filter ancestor=go-k8s-pipeline:test)`

### Step 3: Push to Repository
- [ ] Commit changes: `git add . && git commit -m "Deploy v1.0"`
- [ ] Push to master: `git push origin master`
- [ ] Verify GitHub Actions workflow runs successfully
- [ ] Check Docker Hub for new image

### Step 4: Update Kubernetes Manifests
- [ ] Update `k8s/deployment.yaml` with your Docker Hub username
- [ ] Update `k8s/kustomization.yaml` with your Docker Hub username
- [ ] Review resource limits and requests
- [ ] Verify replica count (default: 3)

### Step 5: Deploy to Kubernetes

#### Option A: Automated (GitHub Actions)
- [ ] Go to GitHub Actions
- [ ] Run workflow manually
- [ ] Select target branch
- [ ] Choose environment (staging/production)
- [ ] Enable "Deploy to Kubernetes"
- [ ] Monitor workflow execution
- [ ] Check deployment status in logs

#### Option B: Manual Deployment
- [ ] Export Docker Hub username: `export DOCKERHUB_USERNAME="your-username"`
- [ ] Run deployment script: `./scripts/deploy.sh`
- [ ] Or apply manually: `kubectl apply -f k8s/`
- [ ] Wait for rollout: `kubectl rollout status deployment/go-service`

### Step 6: Verify Deployment
- [ ] Check deployment: `kubectl get deployments`
- [ ] Check pods: `kubectl get pods -l app=go-service`
- [ ] All pods in Running state
- [ ] All pods show READY (1/1)
- [ ] Check service: `kubectl get service go-service`
- [ ] Note external IP or configure port-forward

### Step 7: Test Deployed Application

#### If using LoadBalancer:
- [ ] Wait for external IP: `kubectl get service go-service --watch`
- [ ] Test endpoint: `curl http://<EXTERNAL-IP>`
- [ ] Should see: "Hello from Go + Docker"

#### If using port-forward:
- [ ] Forward port: `kubectl port-forward service/go-service 8080:80`
- [ ] Test locally: `curl http://localhost:8080`
- [ ] Should see: "Hello from Go + Docker"

### Step 8: Monitor Application
- [ ] View logs: `kubectl logs -l app=go-service -f`
- [ ] Check resource usage: `kubectl top pods -l app=go-service`
- [ ] Monitor events: `kubectl get events --sort-by='.lastTimestamp'`
- [ ] Set up alerts (optional)

## Post-Deployment Checklist

### Immediate Actions
- [ ] Verify all pods are healthy
- [ ] Test all endpoints
- [ ] Check application logs for errors
- [ ] Verify external access works
- [ ] Document deployment details (version, timestamp, etc.)

### Configuration
- [ ] Configure horizontal pod autoscaling (if needed)
- [ ] Set up ingress (if needed)
- [ ] Configure monitoring and alerting
- [ ] Set up log aggregation

### Documentation
- [ ] Update deployment documentation
- [ ] Document any issues encountered
- [ ] Update runbook with any new procedures
- [ ] Share deployment details with team

### Clean Up
- [ ] Remove any old deployments
- [ ] Clean up temporary files
- [ ] Remove unused Docker images from local machine

## Rollback Checklist (If Issues Occur)

- [ ] Identify the issue
- [ ] Decide to rollback or fix forward
- [ ] If rollback: Run `./scripts/rollback.sh` or `kubectl rollout undo deployment/go-service`
- [ ] Verify rollback: `kubectl rollout status deployment/go-service`
- [ ] Test application after rollback
- [ ] Investigate root cause
- [ ] Document issue and resolution

## Troubleshooting Guide

### Pods Not Starting

**Check**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
```

**Common issues**:
- [ ] Image pull errors (check image name, Docker Hub credentials)
- [ ] Resource constraints (insufficient CPU/memory)
- [ ] Config errors (check environment variables)

### Service Not Accessible

**Check**:
```bash
kubectl get endpoints go-service
kubectl describe service go-service
```

**Common issues**:
- [ ] Service selector doesn't match pod labels
- [ ] Firewall rules blocking access
- [ ] LoadBalancer not provisioned (cloud-specific)

### Application Errors

**Check**:
```bash
kubectl logs -l app=go-service --tail=100
kubectl exec -it <pod-name> -- /bin/sh
```

**Common issues**:
- [ ] Configuration errors
- [ ] Missing environment variables
- [ ] Port conflicts

## Performance Tuning

After successful deployment, consider:

- [ ] Adjust replica count based on load
- [ ] Configure HPA (Horizontal Pod Autoscaler)
- [ ] Tune resource requests and limits
- [ ] Set up probes (liveness, readiness, startup)
- [ ] Configure pod disruption budget
- [ ] Optimize Docker image size

## Security Hardening

- [ ] Run as non-root user in container
- [ ] Use read-only root filesystem
- [ ] Drop unnecessary capabilities
- [ ] Implement network policies
- [ ] Use secrets for sensitive data
- [ ] Regular security scans
- [ ] Keep dependencies updated

## Next Deployment

Before next deployment:
- [ ] Review and update this checklist
- [ ] Document any new steps or issues
- [ ] Update scripts if needed
- [ ] Test in staging first
- [ ] Schedule deployment during low-traffic period

## Contact Information

**On-Call Support**: [Add contact info]
**Slack Channel**: [Add channel]
**Documentation**: README.md, KUBERNETES.md, CICD_SETUP.md

## Notes

Use this space to record deployment-specific notes:

```
Date: _______________
Version: _______________
Deployed by: _______________
Notes: 
_______________________________________________
_______________________________________________
_______________________________________________
```

