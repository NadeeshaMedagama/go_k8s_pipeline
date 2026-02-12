# Quick Reference: Automatic & Manual CI/CD Triggers

## 🚀 Project: go_k8s_pipeline

---

## Trigger Options

### ⚡ Option 1: Automatic Deployment (PUSH TO MASTER)

**When**: Every push to the `master` branch

**What happens**:
1. ✅ Tests run
2. ✅ Docker image built and pushed
3. ✅ **Automatically deploys to Kubernetes (production)**

**Command**:
```bash
git add .
git commit -m "Your changes"
git push origin master
```

**Logs will show**: 🚀 Automatic deployment triggered by push to master branch

---

### 🎯 Option 2: Manual Deployment (WORKFLOW DISPATCH)

**When**: Manually triggered via GitHub Actions UI

**What happens**:
1. ✅ Tests run
2. ✅ Docker image built and pushed
3. ✅ Deploys to Kubernetes (if enabled)
4. ✅ You choose: staging or production

**How to trigger**:
1. Go to GitHub → Actions tab
2. Select "Go CI/CD Pipeline"
3. Click "Run workflow"
4. Configure:
   - **Branch**: `master`
   - **Environment**: `staging` or `production`
   - **Deploy to Kubernetes**: `true` or `false`
5. Click "Run workflow"

**Logs will show**: 🎯 Manual deployment triggered via workflow_dispatch

---

### 🧪 Option 3: Pull Request (TESTING ONLY)

**When**: Pull request created/updated targeting master

**What happens**:
1. ✅ Tests run
2. ❌ No build
3. ❌ No deployment

**Command**:
```bash
git checkout -b feature/my-feature
git push origin feature/my-feature
# Create PR on GitHub targeting master
```

---

## Modified Files

### 1. `.github/workflows/ci-cd.yml`
- Added automatic K8s deployment on push to master
- Enhanced deploy-k8s job condition
- Added deployment type identification
- Environment-aware notifications

### 2. `README.md`
- Updated trigger methods section
- Enhanced K8s deployment description
- Added automatic deployment details

### 3. `docs/CICD_SETUP.md`
- Documented automatic K8s deployment
- Updated pipeline stages
- Added environment selection info

### 4. `docs/QUICKSTART.md`
- Updated trigger pipeline section
- Added automatic deployment explanation

### 5. `docs/PROJECT_SUMMARY.md`
- Reordered deployment options
- Enhanced CI/CD pipeline description

### 6. `BRANCH_UPDATE_SUMMARY.md` ⭐ NEW
- Complete branch update documentation

---

## Workflow Behavior

| Trigger | Event | Environment | K8s Deploy |
|---------|-------|-------------|------------|
| **Auto** | Push to master | production | ✅ Yes |
| **Manual** | workflow_dispatch | User choice | Optional |
| **Auto** | Pull request | N/A | ❌ No |

---

## Key Points

✅ **Push to master** = Automatic deployment to production  
✅ **Manual trigger** = Full control over environment  
✅ **Pull requests** = Tests only  
✅ **Clear logging** = Know which type triggered  
✅ **All docs updated** = Consistent information  

---

## Testing Your Setup

### Test Automatic Deployment:
```bash
echo "Test automatic deployment" >> test.txt
git add test.txt
git commit -m "Test auto deploy"
git push origin master
# Watch GitHub Actions tab
```

### Test Manual Deployment:
1. GitHub → Actions → "Go CI/CD Pipeline"
2. Run workflow → staging → deploy=true
3. Monitor deployment

### Verify Deployment:
```bash
kubectl get deployments go-service
kubectl get pods -l app=go-service
kubectl logs -l app=go-service -f
```

---

## Need Help?

📖 **Full Documentation**: See `BRANCH_UPDATE_SUMMARY.md`  
📚 **CI/CD Setup**: See `docs/CICD_SETUP.md`  
🚀 **Quick Start**: See `docs/QUICKSTART.md`  
📋 **Main Docs**: See `README.md`

---

**Status**: ✅ Ready to use  
**Branch**: master  
**Last Updated**: February 11, 2026

