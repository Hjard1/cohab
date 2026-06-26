#!/bin/bash
set -e

DEVICE_ID="BECF664B-FA8A-5D11-BE4D-CC9D26E97813"
SCHEME="Cohab"
BUNDLE_ID="com.hjard.cohab"
DERIVED_DATA=~/Library/Developer/Xcode/DerivedData/Cohab-device
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/Cohab.app"

echo "⚙️  Generating Xcode project..."
cd "$(dirname "$0")"
xcodegen generate --quiet

echo "🔨 Building for device..."
xcodebuild \
  -project Cohab.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" || true

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Build failed — ingen .app funnet"
  exit 1
fi

echo "📲 Installerer på iPhone..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "🚀 Starter appen..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null \
  || echo "(Lås opp telefonen for å starte)"

echo "✅ Deploy ferdig!"
