# GitHub Runner Kubernetes Deployment Steps

## Prerequisites
- Kubernetes cluster access (`kubectl` configured)
- Container registry access (to push the runner image)
- GitHub registration token (from Repo/Org Settings → Actions → Runners → New self-hosted runner)

## Step 1: Build and Push the Runner Image

### 1.1 Build the image locally
```bash
cd /home/dasm/org-dasmlab/infra/ci-cd-agents
./buildme_local.sh
```

### 1.2 Tag and push to registry
The image will be pushed to `ghcr.io/dasmlab/ci-cd-github-runner`. You can either:

**Option A: Use pushme.sh (automatic versioning)**
```bash
./pushme.sh
```

**Option B: Manual tag and push**
```bash
docker tag ci-cd-github-runner:local ghcr.io/dasmlab/ci-cd-github-runner:latest
docker push ghcr.io/dasmlab/ci-cd-github-runner:latest
```

**Option C: Use commit_me.sh (builds, tags, and pushes automatically)**
```bash
./commit_me.sh point "Your commit message"
# This will build, tag with version, and push both versioned and latest tags
```

## Step 2: Create Kubernetes Secret

### 2.1 Create the secret from template
```bash
cd k8s
cp github-runner-secret.yaml.template github-runner-secret.yaml
```

### 2.2 Edit the secret file
Replace `YOUR_REGISTRATION_TOKEN_HERE` with your actual GitHub registration token:
```bash
# Edit github-runner-secret.yaml
# Replace: github_token: "YOUR_REGISTRATION_TOKEN_HERE"
# With: github_token: "AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

### 2.3 Apply the secret
```bash
kubectl apply -f github-runner-secret.yaml
```

**Note:** Registration tokens expire after 1 hour. If you need to re-register later, you'll need to:
1. Get a new token from GitHub
2. Update the secret: `kubectl create secret generic github-runner-secrets --from-literal=github_token=NEW_TOKEN --dry-run=client -o yaml | kubectl apply -f -`

## Step 3: Update Deployment Manifest

### 3.1 Edit the deployment file
Edit `k8s/github-runner-deployment.yaml`:

1. **Update the image (if not using latest):**
   ```yaml
   image: ghcr.io/dasmlab/ci-cd-github-runner:latest
   # Or use a versioned tag: ghcr.io/dasmlab/ci-cd-github-runner:0.1.5-alpha
   ```
   Note: The default is already set to `ghcr.io/dasmlab/ci-cd-github-runner:latest`

2. **Update the repository URL:**
   ```yaml
   - name: GITHUB_REPO_URL
     value: "https://github.com/YOUR_ORG/YOUR_REPO"
   ```
   - For **repository-level runner**: `https://github.com/org/repo`
   - For **organization-level runner**: `https://github.com/org`

3. **Optional: Customize runner name:**
   ```yaml
   - name: RUNNER_NAME
     value: "k8s-runner-prod"  # Your custom name
   ```

4. **Optional: Update namespace** if not using `default`

## Step 4: Create GHCR.io Image Pull Secret

The deployment needs access to pull images from `ghcr.io/dasmlab`. Create the secret:

```bash
# Create the image pull secret in your namespace (default shown)
./scripts/create-registry-secret.sh default

# Or specify a different namespace:
./scripts/create-registry-secret.sh your-namespace
```

This script reads the token from `/home/dasm/gh_token` and creates the `dasmlab-ghcr-pull` secret that the deployment references in `imagePullSecrets`.

**Note:** The deployment manifest already includes `imagePullSecrets` pointing to `dasmlab-ghcr-pull`, so this step is required before deploying.

## Step 5: Create Registry Secret for Workflows (if needed)

If your workflows push images to a registry, create the registry secret:
```bash
kubectl create secret generic registry-secrets \
  --from-literal=password='YOUR_REGISTRY_PASSWORD' \
  --namespace=default
```

## Step 6: Deploy the Runner

```bash
kubectl apply -f k8s/github-runner-deployment.yaml
```

## Step 7: Verify Deployment

### Check pod status
```bash
kubectl get pods -l app=github-actions-runner
```

### Check pod logs
```bash
kubectl logs -l app=github-actions-runner -f
```

You should see:
- "Configuring runner..." (first time)
- "Runner configured successfully. Starting..."
- Runner connecting to GitHub

### Check runner in GitHub
1. Go to your repository/org → Settings → Actions → Runners
2. You should see your runner listed (may take a minute to appear)

## Step 8: Test the Runner

Create a test workflow in your repository:
```yaml
name: Test Runner
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3
      - name: Test
        run: echo "Runner is working!"
```

## Troubleshooting

### Runner not appearing in GitHub
- Check pod logs: `kubectl logs -l app=github-actions-runner`
- Verify token is valid (tokens expire after 1 hour)
- Check network connectivity from pod to GitHub

### Runner keeps restarting
- Check pod logs for errors
- Verify all required environment variables are set
- Check resource limits if pod is being OOMKilled

### Jobs not being picked up
- Verify runner labels match workflow `runs-on` requirements
- Check runner status in GitHub UI
- Ensure runner is in "Idle" state (not "Offline")

## Updating the Runner

### Update the image
1. Build new image: `./buildme_local.sh`
2. Tag and push: `docker tag ... && docker push ...`
3. Update deployment: `kubectl set image deployment/github-actions-runner runner=<new-image>`

### Scale runners
```bash
kubectl scale deployment github-actions-runner --replicas=3
```

## Cleanup

To remove the runner:
```bash
kubectl delete -f k8s/github-runner-deployment.yaml
kubectl delete secret github-runner-secrets  # Optional
```

Then remove the runner from GitHub UI (Settings → Actions → Runners).

