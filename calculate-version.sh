#!/bin/sh
set -eu

VERSION="0.1.2"

# Describe nearest tag in history that matches SemVer pattern
DESC=$(git describe --tags --match '[0-9]*.[0-9]*.[0-9]*' --abbrev=7 2>/dev/null || true)

if [ -z "$DESC" ]; then
    echo "❌ No matching SemVer tag found via git describe"
    exit 1
fi

# Parse components
case "$DESC" in
  *-*-g*)
    BASE_TAG=$(echo "$DESC" | sed -E 's/-[0-9]+-g[0-9a-f]+$//')
    COUNT=$(echo "$DESC" | sed -E 's/^.*-([0-9]+)-g[0-9a-f]+$/\1/')
    SHA=$(echo "$DESC" | sed -E 's/^.*-g([0-9a-f]+)$/\1/')
    ;;
  *)
    BASE_TAG="$DESC"
    COUNT=0
    SHA=""
    ;;
esac

# Check base tag is not greater than current version
if command -v dpkg >/dev/null 2>&1; then
    dpkg --compare-versions "$BASE_TAG" "gt" "$VERSION" && {
        echo "❌ Nearest tag '$BASE_TAG' is newer than declared version '$VERSION'"
        exit 1
    }
fi

# Check if we are on a tag
if [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
    TAG="${GITHUB_REF##refs/tags/}"
    if [ "$TAG" != "$VERSION" ]; then
        echo "❌ Action was triggered on tag '$TAG', expected '$VERSION'"
        exit 1
    fi
else
    SUFFIX="+${COUNT}-g${SHA}"
fi

echo "detected version: $VERSION$SUFFIX"
echo "version=$VERSION$SUFFIX" >> "$GITHUB_ENV"
