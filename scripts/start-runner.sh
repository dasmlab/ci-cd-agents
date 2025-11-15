#!/bin/bash
set -e

# GitHub Actions Runner startup script for Kubernetes
# This script configures and starts the runner on container startup

cd /home/runner

# Check if runner is already configured
if [ -f ".runner" ]; then
    echo "Runner already configured, starting..."
    ./run.sh
else
    echo "Configuring runner..."
    
    # Validate required environment variables
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "ERROR: GITHUB_TOKEN environment variable is required"
        exit 1
    fi
    
    if [ -z "$GITHUB_REPO_URL" ]; then
        echo "ERROR: GITHUB_REPO_URL environment variable is required (e.g., https://github.com/org/repo)"
        exit 1
    fi
    
    # Set default runner name if not provided
    RUNNER_NAME=${RUNNER_NAME:-"k8s-runner-$(hostname)"}
    
    # Configure the runner
    ./config.sh \
        --url "$GITHUB_REPO_URL" \
        --token "$GITHUB_TOKEN" \
        --name "$RUNNER_NAME" \
        --work "_work" \
        --replace \
        --unattended
    
    echo "Runner configured successfully. Starting..."
    
    # Start the runner
    ./run.sh
fi

