#!/bin/bash
# Setup and run AHMA Flutter app with NetworkManager workaround

echo "🔧 AHMA App Setup & Runner"
echo "=========================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
   echo "❌ Please do not run this script as root"
   exit 1
fi

# Step 1: Start DBus if not running
if ! pgrep -x "dbus-daemon" > /dev/null; then
    echo "📡 Starting DBus..."
    sudo service dbus start
else
    echo "✅ DBus is running"
fi

# Step 2: Start NetworkManager
echo "📡 Starting NetworkManager..."
sudo systemctl start NetworkManager 2>/dev/null || echo "⚠️  NetworkManager may not be available"

# Step 3: Check NetworkManager status
if systemctl is-active --quiet NetworkManager; then
    echo "✅ NetworkManager is running"
else
    echo "⚠️  NetworkManager is not running - app may have connectivity issues"
    echo "   Continuing anyway..."
fi

# Step 4: Navigate to app directory
cd "$(dirname "$0")"

# Step 5: Set Flutter path
FLUTTER_PATH="/home/aparanjape/ahma/flutter/bin/flutter"

echo ""
echo "🚀 Starting AHMA Flutter App..."
echo ""
echo "Make sure you have:"
echo "  ✓ Filled in .env file with API keys"
echo "  ✓ Started backend server (in another terminal)"
echo ""

# Step 6: Run the app
$FLUTTER_PATH run -d linux
