# CI/CD Setup Guide

This guide explains how to set up and use the GitHub Actions CI/CD pipelines for automated testing, building, security analysis, and deployment.

## Overview

The go_k8s_pipeline project includes multiple automated pipelines:

### Main CI/CD Pipeline (`ci-cd.yml`)
1. **Test**: Runs unit tests and generates coverage reports
2. **Build and Push**: Builds Docker images and pushes to Docker Hub

### CodeQL Security Analysis Pipeline (`codeql-analysis.yml`)
- Automated security scanning using GitHub CodeQL
- Runs on every push, pull request, and daily at 2:00 AM UTC
- Detects security vulnerabilities and code quality issues

### Docker Build and Test Pipeline (`docker-test.yml`)
- Builds Docker images locally for testing
- Runs container tests to verify functionality
- Scans images for vulnerabilities using Trivy
- Runs on every push and pull request

### Release Pipeline (`release.yml`)
- Triggered by version tags (e.g., `v1.0.0`)
- Builds binaries for multiple platforms (Linux, macOS, Windows)
- Creates multi-architecture Docker images
- Publishes GitHub releases with artifacts

### Dependabot (`dependabot.yml`)
- Automatically checks for dependency updates weekly
- Creates pull requests for Go modules, Docker base images, and GitHub Actions
- Runs every Monday at 2:00 AM UTC

## Prerequisites

- GitHub repository with this project (go_k8s_pipeline)
- GitHub Advanced Security enabled (for CodeQL analysis)
- Docker Hub account
- (Optional) Kubernetes cluster for deployments

## Initial Setup

### 1. Configure GitHub Secrets

Go to your GitHub repository:
1. Click on **Settings**
2. Navigate to **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add the following secrets:

#### Required Secrets

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Your username on hub.docker.com |
| `DOCKERHUB_TOKEN` | Docker Hub access token | See instructions below |

#### Optional Secrets (for Kubernetes deployment)

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `KUBECONFIG` | Base64-encoded kubeconfig | See instructions below |

### 2. Create Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com)
2. Click on your username → **Account Settings**
3. Navigate to **Security** → **Access Tokens**
4. Click **New Access Token**
5. Give it a description (e.g., "GitHub Actions")
6. Set permissions to **Read, Write, Delete**
7. Click **Generate**
8. Copy the token (you won't see it again!)
9. Add it as `DOCKERHUB_TOKEN` secret in GitHub

### 3. Create KUBECONFIG Secret (Optional)

For Kubernetes deployments:

```bash
# On your machine with kubectl configured
cat ~/.kube/config | base64 -w 0

# Or on macOS
cat ~/.kube/config | base64

# Copy the output
```

Then:
1. Go to GitHub repository secrets
2. Create new secret named `KUBECONFIG`
3. Paste the base64-encoded content
4. Save

## Trigger Methods

### Automatic Triggers

The pipeline automatically runs on:

#### 1. Push to Master Branch
```bash
git add .
git commit -m "Your changes"
git push origin master
```

This will:
- Run tests
- Build and push Docker image with tags: `latest`, `main-<commit-sha>`
- **Automatically deploy to Kubernetes** (production environment)

#### 2. Pull Requests
```bash
git checkout -b feature/my-feature
git add .
git commit -m "Add new feature"
git push origin feature/my-feature
# Create PR on GitHub
```

This will:
- Only run tests (no build/deploy)

### Manual Trigger

#### Using GitHub UI

1. Go to your repository on GitHub
2. Click on the **Actions** tab
3. Select **Go CI/CD Pipeline** from the workflow list
4. Click **Run workflow** (top right)
5. Configure options:
   - **Branch**: Select branch to deploy from
   - **Environment**: Choose `staging` or `production`
   - **Deploy to Kubernetes**: Set to `true` for K8s deployment
6. Click **Run workflow**

#### Using GitHub CLI

```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Trigger workflow without K8s deployment
gh workflow run "Go CI/CD Pipeline" \
  --ref main \
  -f environment=staging \
  -f deploy_to_k8s=false

# Trigger workflow with K8s deployment
gh workflow run "Go CI/CD Pipeline" \
  --ref main \
  -f environment=production \
  -f deploy_to_k8s=true
```

#### Using GitHub API

```bash
# Replace <OWNER>, <REPO>, and <TOKEN>
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token <TOKEN>" \
  https://api.github.com/repos/<OWNER>/<REPO>/actions/workflows/ci-cd.yml/dispatches \
  -d '{"ref":"main","inputs":{"environment":"production","deploy_to_k8s":"true"}}'
```

## Pipeline Stages Explained

### Stage 1: Test Job

**Runs on**: Every push, PR, and manual trigger

**Steps**:
1. Checkout code
2. Set up Go 1.22 environment
3. Cache Go modules (speeds up future runs)
4. Run tests with race detection
5. Generate coverage report
6. Upload coverage artifact

**View results**:
- Check GitHub Actions tab for test results
- Download coverage report from artifacts

### Stage 2: Build and Push Job

**Runs on**: Push to master, manual trigger

**Steps**:
1. Checkout code
2. Set up Docker Buildx
3. Login to Docker Hub
4. Extract metadata (tags, labels)
5. Build Docker image
6. Push to Docker Hub with multiple tags

**Image tags created**:
- `latest` (only on master branch)
- `master-<commit-sha>`
- `master`

### Stage 3: Deploy to Kubernetes Job

**Runs on**: 
- Automatic: Push to master branch
- Manual: workflow_dispatch with `deploy_to_k8s=true`

**Steps**:
1. Checkout code
2. Identify deployment trigger (automatic vs manual)
3. Configure kubectl with KUBECONFIG secret
4. Update Kubernetes manifests with correct image
5. Apply deployment and service manifests
6. Wait for rollout to complete (5-minute timeout)
7. Display deployment status

**Environment Selection**:
- Automatic deployments: `production` (default)
- Manual deployments: User-selected (staging or production)

## Viewing Pipeline Results

### On GitHub

1. Go to **Actions** tab
2. Click on a workflow run
3. View logs for each job
4. Download artifacts (e.g., coverage reports)

### Status Badge

Add this to your README.md:

```markdown
![CI/CD Status](https://github.com/<owner>/<repo>/workflows/Go%20CI/CD%20Pipeline/badge.svg)
```

## Advanced Configuration

### Customize Deployment

Edit `.github/workflows/ci-cd.yml`:

```yaml
# Change Go version
- name: Set up Go
  uses: actions/setup-go@v5
  with:
    go-version: "1.25"  # Change this

# Add more environments
workflow_dispatch:
  inputs:
    environment:
      type: choice
      options:
        - staging
        - production
        - development  # Add this
```

### Add Environment-Specific Deployments

```yaml
deploy-k8s:
  steps:
    - name: Deploy to Kubernetes
      run: |
        if [ "${{ github.event.inputs.environment }}" == "production" ]; then
          kubectl apply -f k8s/deployment.yaml --namespace=production
        else
          kubectl apply -f k8s/deployment.yaml --namespace=staging
        fi
```

### Add Notifications

#### Slack Notification

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

#### Email Notification

GitHub automatically sends email notifications for workflow failures if enabled in your settings.

### Add Security Scanning

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ secrets.DOCKERHUB_USERNAME }}/go_k8s_pipeline:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload Trivy results
  uses: github/codeql-action/upload-sarif@v4
  with:
    sarif_file: 'trivy-results.sarif'
```

## Additional Pipelines

### CodeQL Security Analysis

The CodeQL pipeline automatically scans your Go code for security vulnerabilities and code quality issues.

**Triggers**:
- Push to `master` branch
- Pull requests to `master` branch
- Daily at 2:00 AM UTC (scheduled scan)

**What it does**:
- Analyzes Go source code for security vulnerabilities
- Checks for common coding errors and anti-patterns
- Uses security-extended queries for comprehensive scanning
- Uploads results to GitHub Security tab

**Viewing Results**:
1. Go to **Security** tab in your repository
2. Click **Code scanning alerts**
3. Review any detected issues
4. Click on an alert for details and remediation advice

**Configuration**: `.github/workflows/codeql-analysis.yml`

### Docker Build and Test Pipeline

This pipeline tests Docker builds in isolation and scans for vulnerabilities.

**Triggers**:
- Push to `master` branch
- Pull requests to `master` branch
- Manual workflow dispatch

**What it does**:
1. Builds Docker image locally (doesn't push)
2. Starts container and tests HTTP endpoint
3. Verifies response content
4. Scans image with Trivy for vulnerabilities
5. Uploads security results to GitHub Security

**Test Details**:
```bash
# Tests performed:
- HTTP 200 response check
- Response content verification ("Hello from Go + Docker")
- Container startup and health check
```

**Configuration**: `.github/workflows/docker-test.yml`

### Release Pipeline

Creates official releases with binaries and Docker images.

**Triggers**:
- Push tags matching `v*.*.*` (e.g., `v1.0.0`, `v2.1.3`)
- Manual workflow dispatch with version input

**Creating a Release**:

```bash
# Tag your release
git tag v1.0.0
git push origin v1.0.0

# Or create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**What it does**:
1. **Build Job**: Compiles binaries for multiple platforms
   - Linux (amd64, arm64)
   - macOS (amd64, arm64)
   - Windows (amd64)
   - Generates SHA256 checksums

2. **Docker Job**: Builds and pushes multi-architecture Docker images
   - Creates semantic version tags (e.g., `1.0.0`, `1.0`, `1`)
   - Tags with `latest`
   - Supports linux/amd64 and linux/arm64

3. **Release Job**: Creates GitHub release
   - Uploads all binaries and checksums
   - Generates changelog from git commits
   - Includes Docker pull instructions

**Docker Image Tags Created**:
```
youruser/go_k8s_pipeline:1.0.0
youruser/go_k8s_pipeline:1.0
youruser/go_k8s_pipeline:1
youruser/go_k8s_pipeline:latest
```

**Configuration**: `.github/workflows/release.yml`

### Dependabot Updates

Automatically creates pull requests for dependency updates.

**Schedule**: Every Monday at 2:00 AM UTC

**What it monitors**:
1. **Go Modules** (`go.mod`)
   - Go language version
   - Third-party packages
   - Creates PRs with prefix: `chore(go):`

2. **Docker Base Images** (`Dockerfile`)
   - Base image updates (e.g., golang:1.25-alpine)
   - Creates PRs with prefix: `chore(docker):`

3. **GitHub Actions** (`.github/workflows/*.yml`)
   - Action version updates
   - Creates PRs with prefix: `chore(github-actions):`

**Configuration**: `.github/dependabot.yml`

**Managing Dependabot PRs**:
1. Review the PR created by Dependabot
2. Check the changelog and release notes
3. Ensure CI/CD pipelines pass
4. Merge if tests pass and changes look good

**Customization**:
```yaml
# Adjust schedule
schedule:
  interval: "daily"  # or "weekly", "monthly"
  
# Limit PRs
open-pull-requests-limit: 5

# Change labels
labels:
  - "dependencies"
  - "automerge"  # For automated merging
```

## Troubleshooting

### Pipeline Fails at Docker Login

**Error**: "Error: Cannot perform an interactive login from a non TTY device"

**Solution**: 
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are set correctly
- Make sure the token has proper permissions

### Pipeline Fails at Kubernetes Deployment

**Error**: "The connection to the server localhost:8080 was refused"

**Solution**:
- Verify `KUBECONFIG` secret is set and properly base64 encoded
- Ensure kubeconfig has valid credentials
- Check if your cluster is accessible from GitHub Actions runners

### Image Pull Errors in Kubernetes

**Error**: "Failed to pull image: unauthorized"

**Solution**:
```bash
# Create image pull secret in Kubernetes
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<password>

# Update deployment
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "dockerhub-secret"}]}'
```

### Tests Failing

**Check**:
- View test logs in Actions tab
- Run tests locally: `go test -v ./...`
- Check for race conditions: `go test -race ./...`

### Build Timeout

**Solution**: Increase timeout in workflow:

```yaml
jobs:
  build-and-push:
    timeout-minutes: 30  # Default is 360
```

## Best Practices

### 1. Branch Protection

Configure branch protection rules:
1. Go to **Settings** → **Branches**
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

### 2. Testing Strategy

- Write comprehensive tests
- Use test coverage reports
- Set minimum coverage threshold

### 3. Image Tagging

- Use semantic versioning for releases
- Tag with commit SHA for traceability
- Keep `latest` for master branch only

### 4. Deployment Strategy

- Use staging environment for testing
- Implement blue-green or canary deployments
- Always test in staging before production

### 5. Security

- Regularly rotate Docker Hub tokens
- Use secrets for sensitive data
- Enable Dependabot for dependency updates
- Scan images for vulnerabilities

## Monitoring Pipeline Performance

### View Pipeline History

```bash
# Using GitHub CLI
gh run list --workflow=ci-cd.yml --limit 20

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### Pipeline Metrics to Track

- Average execution time
- Success rate
- Test coverage trends
- Build cache hit rate

## Next Steps

- [x] Set up Dependabot for automatic dependency updates
- [x] Add CodeQL security analysis
- [x] Add Docker vulnerability scanning with Trivy
- [x] Implement release pipeline
- [ ] Add integration tests
- [ ] Implement canary deployments
- [ ] Add performance testing
- [ ] Set up monitoring and alerting
- [ ] Configure multi-environment deployments
- [ ] Add approval gates for production

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Azure Kubernetes Set Context](https://github.com/Azure/k8s-set-context)
- [Go GitHub Actions](https://github.com/actions/setup-go)

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Review this guide
3. Check GitHub Actions documentation
4. Open an issue in the repository

