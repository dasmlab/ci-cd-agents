#!/usr/bin/env bash
set -euo pipefail

# Create GHCR.io image pull secret for Kubernetes
# Reads token from /home/dasm/gh_token

GH_TOKEN_FILE="${GH_TOKEN_FILE:-/home/dasm/gh_token}"
NAMESPACE="${1:-default}"

if [[ ! -f "$GH_TOKEN_FILE" ]]; then
    echo "❌ Error: GH token file not found at ${GH_TOKEN_FILE}"
    echo "   Set GH_TOKEN_FILE environment variable to override location"
    exit 1
fi

GHCR_PAT=$(cat "$GH_TOKEN_FILE" | tr -d '\n')

if [[ -z "$GHCR_PAT" ]]; then
    echo "❌ Error: Token file is empty"
    exit 1
fi

echo "Creating image pull secret 'dasmlab-ghcr-pull' in namespace '${NAMESPACE}'..."

kubectl create secret docker-registry dasmlab-ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=lmcdasm \
  --docker-password="${GHCR_PAT}" \
  --docker-email=dasmlab-bot@dasmlab.org \
  --namespace "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret 'dasmlab-ghcr-pull' ensured in namespace '${NAMESPACE}'"

