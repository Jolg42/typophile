#!/bin/bash
set -e

echo "========================================="
echo "Deploying to GitHub Pages"
echo "========================================="
echo ""

# # Check if public directory exists
# if [ ! -d "hugo-site/public" ]; then
#   echo "❌ Error: hugo-site/public directory not found"
#   echo "Run ./build.sh first to build the site"
#   exit 1
# fi

# # Save current branch
# CURRENT_BRANCH=$(git branch --show-current)

# echo "Current branch: $CURRENT_BRANCH"
# echo "Deploying hugo-site/public/ to gh-pages branch..."
# echo ""

# Create a temporary directory
# TEMP_DIR=$(mktemp -d)
TEMP_DIR=/var/folders/qt/13pk8tq5113437vp1xr2l_s40000gn/T/tmp.wY7T2wTElE
echo "Using temp directory: $TEMP_DIR"

# # Copy public files to temp (use rsync or tar to handle large file counts)
# echo "Copying files (this may take a minute)..."
# if command -v rsync &> /dev/null; then
#   rsync -a hugo-site/public/ "$TEMP_DIR/"
# else
#   # Fallback: use tar to avoid argument list limits
#   (cd hugo-site/public && tar cf - .) | (cd "$TEMP_DIR" && tar xf -)
# fi

# # Switch to gh-pages branch (create if doesn't exist)
# if git show-ref --verify --quiet refs/heads/gh-pages; then
#   echo "Checking out existing gh-pages branch..."
#   git checkout gh-pages
# else
#   echo "Creating new gh-pages branch..."
#   git checkout --orphan gh-pages
#   git rm -rf .
# fi

# # Remove all existing files (except .git)
# echo "Cleaning gh-pages branch..."
# find . -maxdepth 1 ! -name '.git' ! -name '.' ! -name '..' -exec rm -rf {} +

# Copy files from temp
echo "Copying new files..."
if command -v rsync &> /dev/null; then
  rsync -a "$TEMP_DIR/" .
else
  (cd "$TEMP_DIR" && tar cf - .) | tar xf -
fi

# Show what's being deployed
echo ""
echo "Files to deploy:"
du -sh .
echo "Total files: $(find . -type f | wc -l | xargs)"
echo ""

# Commit
echo "Committing changes..."
git add -A
git commit -m "Deploy Hugo site - $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"

# Push
echo ""
echo "Pushing to fork/gh-pages..."
git push fork gh-pages --force

# Clean up
rm -rf "$TEMP_DIR"

# Return to original branch
echo ""
echo "Returning to $CURRENT_BRANCH branch..."
# git checkout "$CURRENT_BRANCH"

echo ""
echo "========================================="
echo "✅ Deployment complete!"
echo "========================================="
echo ""
echo "Site will be available at:"
echo "https://jolg42.github.io/typophile/"
echo ""
echo "Enable GitHub Pages if not already done:"
echo "1. Go to: https://github.com/Jolg42/typophile/settings/pages"
echo "2. Source: Deploy from a branch"
echo "3. Branch: gh-pages / (root)"
echo "4. Save"
echo ""
