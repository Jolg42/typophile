#!/bin/bash
set -e

echo "========================================="
echo "Typophile Hugo Site Builder"
echo "========================================="
echo ""

# Step 1: Export from SQLite (optional - only if database changed)
if [ "$1" == "--export" ] || [ "$1" == "-e" ]; then
  echo "Step 1: Exporting articles from SQLite..."
  ruby export_to_hugo.rb
  echo "✅ Export complete"
  echo ""
fi

# Step 2: Build Hugo site
echo "Step 2: Building Hugo site..."
cd hugo-site
# https://gohugo.io/commands/hugo/
# --cleanDestinationDir        remove files from destination not found in static directories
# time hugo --minify --cleanDestinationDir
time hugo --minify
cd ..
echo "✅ Build complete"
echo ""

# Step 3: Build Pagefind search index
echo "Step 3: Building Pagefind search index..."
cd hugo-site
npx pagefind --site public
cd ..
echo "✅ Search index complete"
echo ""

# Step 4: Report statistics
echo "========================================="
echo "Build Statistics:"
echo "========================================="
du -sh hugo-site/public/
echo "Pages generated: $(find hugo-site/public -name "index.html" 2>/dev/null | wc -l | xargs)"
echo ""
echo "✅ Site ready in hugo-site/public/"
echo ""
echo "To serve locally, run:"
echo "  ./serve.sh"
