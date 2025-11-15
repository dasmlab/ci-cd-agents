
#!/bin/bash
set -euo pipefail
trap 'echo "❌ Script failed at line $LINENO: $BASH_COMMAND"' ERR

BUMP_TYPE="$1"
shift
MSG="$*"

if [[ -z "$BUMP_TYPE" || -z "$MSG" ]]; then
  echo "Usage: ./commitme.sh [point|minor|major] \"tag message\""
  exit 1
fi

echo "🔄 Pulling latest commits and tags from origin/$(git rev-parse --abbrev-ref HEAD)..."
git pull origin "$(git rev-parse --abbrev-ref HEAD)" --tags

BRANCH=$(git rev-parse --abbrev-ref HEAD)
LATEST_TAG=$(git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$' | sort -V | tail -n 1)

if [[ -z "$LATEST_TAG" ]]; then
  MAJOR=0
  MINOR=0
  PATCH=0
  SUFFIX="-alpha"
else
  VERSION=$(echo "$LATEST_TAG" | cut -d '-' -f1)
  SUFFIX=$(echo "$LATEST_TAG" | grep -oE '\-[a-zA-Z0-9]+$' || echo "-alpha")

  MAJOR=$(echo "$VERSION" | cut -d. -f1 | sed 's/^0*//')
  MINOR=$(echo "$VERSION" | cut -d. -f2 | sed 's/^0*//')
  PATCH=$(echo "$VERSION" | cut -d. -f3 | sed 's/^0*//')

  MAJOR=${MAJOR:-0}
  MINOR=${MINOR:-0}
  PATCH=${PATCH:-0}
fi

echo "📌 Current version: $MAJOR.$MINOR.$PATCH$SUFFIX"

case "$BUMP_TYPE" in
  major)
    echo "🆙 Bumping MAJOR version"
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    echo "🆙 Bumping MINOR version"
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  point)
    echo "🆙 Bumping PATCH version"
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "❌ Invalid bump type: $BUMP_TYPE"
    exit 1
    ;;
esac

NEW_TAG="${MAJOR}.${MINOR}.${PATCH}${SUFFIX}"
echo "🚀 New version will be: $NEW_TAG"

# Check for staged or unstaged changes
git add -A .
if git diff --cached --quiet; then
  echo "⚠️ No staged changes. Aborting. Empty commits are not allowed."
  exit 1
fi

echo "🔧 Committing changes to $BRANCH..."
git commit -m "$MSG"

echo "🏷️  Tagging commit as $NEW_TAG"
git tag -a "$NEW_TAG" -m "$MSG"

echo "📤 Pushing branch '$BRANCH' and tag '$NEW_TAG'..."
git push origin "$BRANCH"
git push origin "$NEW_TAG"

# Build and push Docker image
echo "🐳 Building Docker image..."
./buildme_local.sh

echo "📦 Tagging and pushing Docker image..."
APP="ci-cd-github-runner"
REPO="ghcr.io/dasmlab"
SRC="${APP}:local"
DST_VERSION="${REPO}/${APP}:${NEW_TAG}"
DST_LATEST="${REPO}/${APP}:latest"

# Ensure source image exists
if ! docker image inspect "$SRC" &>/dev/null; then
    echo "❌ Error: Source image ${SRC} not found after build."
    exit 1
fi

# Tag with version and latest
docker tag "$SRC" "$DST_VERSION"
docker tag "$SRC" "$DST_LATEST"

# Push both tags
echo "🚀 Pushing ${DST_VERSION} and ${DST_LATEST}..."
docker push "$DST_VERSION"
docker push "$DST_LATEST"

echo "✅ Done: $NEW_TAG pushed with commit to $BRANCH"
echo "✅ Docker image pushed: ${DST_VERSION} and ${DST_LATEST}"
