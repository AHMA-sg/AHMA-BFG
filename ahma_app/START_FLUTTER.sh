#!/bin/bash
# Start AHMA Flutter App

cd "$(dirname "$0")"

# Set Flutter path
FLUTTER_PATH="/home/aparanjape/ahma/flutter/bin/flutter"

echo "🚀 Starting AHMA Flutter App..."
echo ""
echo "Make sure you have:"
echo "  ✓ Filled in .env file with API keys"
echo "  ✓ Started backend server (in another terminal)"
echo ""

$FLUTTER_PATH run -d linux
