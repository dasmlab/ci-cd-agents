#!/bin/bash
set -e

# Build GitHub Actions runner image
DOCKER_BUILDKIT=1 docker build -f Dockerfile.github-runner -t ci-cd-github-runner:local .

# Build CircleCI runner image
#DOCKER_BUILDKIT=1 docker build -f Dockerfile.circleci-runner -t ci-cd-circleci-runner:local .

echo "Build complete. Images: ci-cd-github-runner:local, ci-cd-circleci-runner:local" 
