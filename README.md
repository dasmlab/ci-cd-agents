# ci-cd-agents - v0.0.2

Ephemeral Kubernetes-native CI/CD runners for GitHub Actions and CircleCI, using Buildah for rootless, secure container builds.

## Features
- No Docker socket mount
- Secure, per-job isolation
- K8s-native resource and secrets handling
- Supports both GitHub Actions and CircleCI

## Structure
- `Dockerfile.github-runner`: Buildah-enabled GitHub Actions runner
- `Dockerfile.circleci-runner`: Buildah-enabled CircleCI runner
- `k8s/`: Sample Kubernetes Job manifests
- `scripts/`: Go script to launch jobs

## Usage
1. Build the runner images and push to your registry.
2. Apply the K8s Job manifests, injecting secrets as needed.
3. Use the Go script to programmatically launch jobs if desired.

## Notes
- See comments in files for customization.
- For rootless Buildah tips and secret handling, see below.

## Rootless Buildah in Kubernetes
- Ensure user namespaces are enabled in your cluster.
- Use `fuse-overlayfs` for storage.
- Avoid privileged containers.

## Secrets
- Use Kubernetes Secrets for runner tokens and registry credentials.
- Reference secrets in your Job manifests as shown in `k8s/*.yaml`. 
