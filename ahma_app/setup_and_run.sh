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

# Step 5: Find Flutter (use system Flutter)
FLUTTER_PATH=$(which flutter)

if [ -z "$FLUTTER_PATH" ]; then
    echo "❌ Flutter not found in PATH"
    echo "   Please install Flutter or add it to your PATH"
    exit 1
fi

echo "✅ Found Flutter at: $FLUTTER_PATH"

# Step 6: Get dependencies
echo ""
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to get dependencies"
    exit 1
fi

echo ""
echo "🚀 Starting AHMA Flutter App..."
echo ""
echo "Prerequisites:"
echo "  ✓ .env file configured with API keys"
echo "  ✓ Backend server running (optional for webhook testing)"
echo ""
echo "📱 Webhook server will start on port 8080"
echo "🧪 To test webhook: python3 test_webhook.py (in another terminal)"
echo ""

# Step 7: Run the app in debug mode (faster iteration)
flutter run -d linux
