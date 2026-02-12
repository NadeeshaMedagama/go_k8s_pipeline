# CI/CD Workflow Diagram

## go_k8s_pipeline - Automatic & Manual Deployment Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TRIGGER METHODS                               │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Push to Master    │  │ Workflow Dispatch│  │  Pull Request    │
│  (Automatic) 🚀  │  │   (Manual) 🎯    │  │   (Testing) 🧪   │
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                      │
         │                     │                      │
┌────────▼─────────────────────▼──────────────────────▼─────────┐
│                         TEST JOB                               │
│  • Checkout code                                               │
│  • Set up Go 1.22                                              │
│  • Cache Go modules                                            │
│  • Run tests with race detection                              │
│  • Generate coverage report                                    │
│  • Upload coverage artifact                                    │
└────────┬─────────────────────┬──────────────────────┬─────────┘
         │                     │                      │
         │                     │                      │
         │                     │                      └──► ❌ STOP
         │                     │                         (PR only tests)
         │                     │
┌────────▼─────────────────────▼────────────────────────────────┐
│                    BUILD AND PUSH JOB                          │
│  • Checkout code                                               │
│  • Set up Docker Buildx                                        │
│  • Login to Docker Hub                                         │
│  • Extract metadata (tags)                                     │
│  • Build Docker image                                          │
│  • Push to Docker Hub                                          │
│    - latest (main only)                                        │
│    - <branch>-<sha>                                            │
│    - <branch>                                                  │
└────────┬─────────────────────┬────────────────────────────────┘
         │                     │
         │                     │
         │                     │  Manual: deploy_to_k8s = false?
         │                     └──────────────► ❌ STOP
         │                                     (Build only)
         │
         │  Push to master OR Manual with deploy_to_k8s = true
         │
┌────────▼────────────────────────────────────────────────────────┐
│                  DEPLOY TO KUBERNETES JOB                        │
│                                                                  │
│  Step 1: Identify Deployment Trigger                            │
│  ┌──────────────────────┬──────────────────────┐               │
│  │  If Push to Master     │  If Manual Trigger   │               │
│  │  🚀 Automatic        │  🎯 Manual           │               │
│  │  Environment: prod   │  Environment: chosen │               │
│  └──────────────────────┴──────────────────────┘               │
│                                                                  │
│  Step 2: Configure kubectl                                      │
│  • Set up kubeconfig from secret                                │
│                                                                  │
│  Step 3: Update Kubernetes Manifests                            │
│  • Replace Docker Hub username                                  │
│                                                                  │
│  Step 4: Deploy to Kubernetes                                   │
│  • kubectl apply -f k8s/deployment.yaml                         │
│  • kubectl apply -f k8s/service.yaml                            │
│                                                                  │
│  Step 5: Wait for Rollout                                       │
│  • kubectl rollout status (5 min timeout)                       │
│                                                                  │
│  Step 6: Get Deployment Status                                  │
│  • Show deployments, pods, services                             │
│                                                                  │
│  Step 7: Notify Result                                          │
│  ┌──────────────────┬──────────────────┐                       │
│  │  ✅ Success      │  ❌ Failure      │                       │
│  │  Env: {env}      │  Env: {env}      │                       │
│  │  Type: {type}    │  Type: {type}    │                       │
│  └──────────────────┴──────────────────┘                       │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │
                    ┌─────────▼──────────┐
                    │  Kubernetes Cluster │
                    │                     │
                    │  go-service         │
                    │  • 3 replicas       │
                    │  • LoadBalancer     │
                    │  • Health checks    │
                    └─────────────────────┘
```

---

## Trigger Comparison

### 🚀 Automatic (Push to Master)

```
Developer Action:
    git push origin master
         │
         ▼
    GitHub Actions
         │
         ├─► Run Tests ✅
         │
         ├─► Build & Push Image ✅
         │
         └─► Deploy to K8s (Production) ✅
              │
              ▼
         Kubernetes Cluster
```

**Features**:
- ⚡ Fastest deployment
- 🎯 Always production
- 🔄 Continuous deployment
- 📦 No manual intervention

---

### 🎯 Manual (Workflow Dispatch)

```
Developer Action:
    GitHub UI → Run Workflow
         │
         ├─ Select Environment: staging/production
         │
         └─ Deploy to K8s: true/false
              │
              ▼
         GitHub Actions
              │
              ├─► Run Tests ✅
              │
              ├─► Build & Push Image ✅
              │
              └─► Deploy to K8s (if enabled) ⚙️
                   │
                   ▼
              Kubernetes Cluster
```

**Features**:
- 🎛️ Full control
- 🌍 Environment selection
- 🔀 Optional deployment
- 🧪 Perfect for staging

---

### 🧪 Pull Request

```
Developer Action:
    Create Pull Request
         │
         ▼
    GitHub Actions
         │
         └─► Run Tests ✅
              │
              ▼
         STOP (No deployment)
```

**Features**:
- ✅ Tests only
- 🛡️ Safe validation
- 🔍 Code review ready
- 🚫 No deployment

---

## Environment Flow

```
┌─────────────────────────────────────────────────────────┐
│                   ENVIRONMENT MATRIX                     │
└─────────────────────────────────────────────────────────┘

Push to Master (Automatic):
    └─► PRODUCTION (fixed)

Manual Workflow Dispatch:
    └─► User chooses:
        ├─► STAGING
        └─► PRODUCTION

Pull Request:
    └─► N/A (no deployment)
```

---

## Decision Tree

```
Is it a Push to Master?
    │
    ├─ YES ──► Run Tests ──► Build Image ──► Deploy to Production
    │
    └─ NO ──► Is it Manual Trigger?
              │
              ├─ YES ──► Run Tests ──► Build Image ──► Deploy to K8s?
              │                                         │
              │                                         ├─ YES ──► Deploy to {selected env}
              │                                         │
              │                                         └─ NO ──► Stop (Build only)
              │
              └─ NO ──► Is it Pull Request?
                        │
                        ├─ YES ──► Run Tests ──► Stop
                        │
                        └─ NO ──► Do nothing
```

---

## Status Indicators

```
┌────────────────────────────────────────────────────────┐
│  Workflow Execution Logs                               │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Automatic Deployment:                                │
│  🚀 Automatic deployment triggered by push to master    │
│  DEPLOYMENT_TYPE=automatic                            │
│  ENVIRONMENT=production                               │
│                                                        │
│  Manual Deployment:                                   │
│  🎯 Manual deployment triggered via workflow_dispatch │
│  DEPLOYMENT_TYPE=manual                               │
│  ENVIRONMENT={staging|production}                     │
│  Target environment: {staging|production}             │
│                                                        │
│  Result:                                              │
│  ✅ Deployment to {environment} completed!            │
│  Deployment type: {automatic|manual}                  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## File Changes Summary

```
Modified Files:
├── .github/workflows/ci-cd.yml       ⭐ Main workflow
├── README.md                         📝 Updated
├── docs/CICD_SETUP.md               📝 Updated
├── docs/QUICKSTART.md               📝 Updated
└── docs/PROJECT_SUMMARY.md          📝 Updated

New Files:
├── CHANGES_SUMMARY.md               ✨ Complete change log
└── TRIGGER_REFERENCE.md             ✨ Quick reference
```

---

## Quick Commands

```bash
# Automatic Deployment
git push origin master

# Check Deployment Status
kubectl get deployments go-service
kubectl get pods -l app=go-service
kubectl logs -l app=go-service -f

# Port Forward (Local Access)
kubectl port-forward service/go-service 8080:80

# Test Application
curl http://localhost:8080
```

---

**Project**: go_k8s_pipeline  
**Version**: 2.0.0  
**Status**: ✅ Complete with Dual Trigger Support  
**Date**: February 11, 2026

