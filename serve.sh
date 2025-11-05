#!/bin/bash

PORT=${1:-8080}

echo "========================================="
echo "Serving Typophile Archive"
echo "========================================="
echo ""
echo "Server will be available at:"
echo "  http://localhost:${PORT}/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd hugo-site/public

# Use Python if available, otherwise Ruby
if command -v python3 &> /dev/null; then
  echo "Using Python HTTP server..."
  python3 -m http.server $PORT
elif command -v ruby &> /dev/null; then
  echo "Using Ruby WEBrick server..."
  ruby -run -ehttpd . -p$PORT
else
  echo "Error: Neither Python 3 nor Ruby found. Please install one of them."
  exit 1
fi
