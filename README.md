# ci-cd-agents

Ephemeral Kubernetes-native CI/CD runners for GitHub Actions and CircleCI, using Buildah for rootless, secure container builds.

## Features
- No Docker socket mount
- Secure, per-job isolation
- K8s-native resource and secrets handling
- Supports both GitHub Actions and CircleCI

## Architecture

```mermaid
flowchart TD
    subgraph "Kubernetes Cluster"
        direction TB
        CIJob["Ephemeral CI/CD Runner Pod\n(GitHub Actions or CircleCI)"]
        subgraph "Pod"
            Runner["Runner Container\n(GitHub Actions or CircleCI)"]
            Builder["Builder Container\n(Buildah, rootless)"]
        end
        PVC["Ephemeral PVC\n(Workspace)"]
        Registry["Container Registry"]
    end
    
    CIJob -->|"Launches"| Runner
    Runner -->|"Triggers build"| Builder
    Builder -->|"Builds image on ephemeral mount"| PVC
    Builder -->|"Pushes image"| Registry
    PVC -.->|"Workspace cleaned up after job"| CIJob
    
    Runner -.->|"Supports both GitHub Actions & CircleCI"| CIJob
    
    classDef github fill:#24292e,stroke:#0366d6,color:#fff;
    classDef circleci fill:#343434,stroke:#13c813,color:#fff;
    class Runner github;
    class Builder circleci;
```

- The runner pod (GitHub Actions or CircleCI) launches in Kubernetes as a Job.
- The runner triggers a builder container (using Buildah, rootless) to build the image.
- The build happens on an ephemeral PVC (workspace) that is discarded after the job.
- The built image is pushed to your container registry.
- No Docker socket or privileged containers required.

## Usage
1. Build the runner images and push to your registry:
   - `./buildme_local.sh`
2. Run a test container locally:
   - `./runme_local.sh`
3. Apply the K8s Job manifests, injecting secrets as needed.
4. Use the Go script to programmatically launch jobs if desired.

## Flavors
- **GitHub Actions**: Uses the GitHub Actions runner and token.
- **CircleCI**: Uses the CircleCI runner and token.

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
