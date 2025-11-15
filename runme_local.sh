#!/bin/bash
set -e

# Check if image exists
if ! docker image inspect ci-cd-github-runner:local &>/dev/null; then
    echo "❌ Image 'ci-cd-github-runner:local' not found."
    echo "   Run './buildme_local.sh' first to build the image."
    exit 1
fi

# Check for required environment variables
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "⚠️  Warning: GITHUB_TOKEN not set. Runner configuration will fail."
    echo "   Set it with: export GITHUB_TOKEN=your_token"
fi

if [[ -z "${GITHUB_REPO_URL:-}" ]]; then
    echo "⚠️  Warning: GITHUB_REPO_URL not set. Runner configuration will fail."
    echo "   Set it with: export GITHUB_REPO_URL=https://github.com/org/repo"
fi

echo "Running a test container from ci-cd-github-runner:local..."
echo "Note: Container will try to configure and start the runner."
echo "      Use Ctrl+C to stop, or run with 'bash' to override entrypoint."
echo ""

# Allow passing additional docker run arguments
docker run --rm -it \
    -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
    -e GITHUB_REPO_URL="${GITHUB_REPO_URL:-}" \
    -e RUNNER_NAME="${RUNNER_NAME:-local-test-runner}" \
    "${@}" \
    ci-cd-github-runner:local 
