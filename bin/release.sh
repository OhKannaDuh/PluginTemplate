#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <tag> [--testing]"
    exit 1
fi

TAG="$1"
IS_TESTING=false
if [ "${2:-}" == "--testing" ]; then
    IS_TESTING=true
fi

# Find first csproj in the solution file in the repo root
SLN_FILE=$(find . -maxdepth 1 -name "*.sln" | head -n 1)
if [ -z "$SLN_FILE" ]; then
    echo "Error: no solution (.sln) file found in repo root."
    exit 1
fi

PROJECT=$(grep -oE '[^"]+\.csproj' "$SLN_FILE" | head -n 1 | sed 's|.csproj||')
if [ -z "$PROJECT" ]; then
    echo "Error: could not determine project name from $SLN_FILE"
    exit 1
fi

ZIP_PATH="$PROJECT/bin/x64/Release/$PROJECT/latest.zip"

# --- Pre-checks -------------------------------------------------------------

# Ensure no uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: You have uncommitted changes. Commit or stash them before releasing."
    exit 1
fi

# Ensure tag doesn't already exist locally or remotely
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: Tag '$TAG' already exists locally."
    exit 1
fi

if git ls-remote --tags origin | grep -q "refs/tags/$TAG"; then
    echo "Error: Tag '$TAG' already exists on remote."
    exit 1
fi

# Ensure version in csproj matches
CS_VERSION=$(xmllint --xpath "string(//Project/PropertyGroup/Version)" "$PROJECT/$PROJECT.csproj")
if [ "$CS_VERSION" != "$TAG" ]; then
    echo "Error: csproj version ($CS_VERSION) does not match tag ($TAG)."
    echo "Fix the version in $PROJECT/$PROJECT.csproj first."
    exit 1
fi

# Ensure CHANGELOG.md mentions the version
if ! grep -q "# $TAG" CHANGELOG.md; then
    echo "Error: CHANGELOG.md does not contain entry for $TAG."
    exit 1
fi

# --- Build ------------------------------------------------------------------

# Clean old zip if present
rm -f "$ZIP_PATH"

echo "Building project..."
dotnet build -c Release

if [ ! -f "$ZIP_PATH" ]; then
    echo "Error: Build failed or $ZIP_PATH not created."
    exit 1
fi

# --- Tag + Release ----------------------------------------------------------

git tag "$TAG"
git push origin master "$TAG"

echo "Creating GitHub release..."
EXTRA_ARGS=()
if [ "$IS_TESTING" = true ]; then
    EXTRA_ARGS+=(--prerelease)
fi
gh release create "$TAG" --title "$TAG" --generate-notes "${EXTRA_ARGS[@]}"
gh release upload "$TAG" "$ZIP_PATH" --clobber

# --- Manifest ----------------------------------------------------------------

echo "Updating manifest repo..."
rm -rf plugins
gh repo clone plugins
cd plugins

cd manifest-generator
npm install
manifest_output=$(npx tsx src/index.ts)
commit_message=$(echo "$manifest_output" | awk '/^Suggested commit message:/{getline; print}')
if [ -z "$commit_message" ]; then
    commit_message="Update Manifest"
fi
cd ..

git add manifest.json
if ! git diff --cached --quiet; then
    git commit -m "$commit_message"
    git push origin master
else
    echo "No manifest changes to commit."
fi

# --- Discord message ---------------------------------------------------------

cd discord-message-generator
npm install
echo "------------------------"
npx tsx src/index.ts
cd ../..

rm -rf plugins

echo "Release $TAG complete."
