#!/bin/bash
set -e

SCHEME="Cohab"
BUNDLE_ID="com.hjard.cohab"
DERIVED_DATA=~/Library/Developer/Xcode/DerivedData/Cohab-device
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/Cohab.app"

# Find first available (unlocked) iOS device — match the UUID identifier
# directly rather than $NF, since the Model column ("iPhone 12 Pro (...)")
# can contain spaces and shift which field is actually last.
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null \
  | grep -E "available.*iPhone" \
  | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}' \
  | head -1)

if [ -z "$DEVICE_ID" ]; then
  # Fall back to hardcoded ID — installs even if phone is locked (but may need unlock to launch)
  DEVICE_ID="BECF664B-FA8A-5D11-BE4D-CC9D26E97813"
  echo "⚠️  Ingen tilgjengelig iPhone funnet — prøver med lagret enhet-ID"
fi

cd "$(dirname "$0")"

if [ ! -d "Cohab.xcodeproj" ]; then
  echo "❌ Cohab.xcodeproj mangler. Avbryter uten å generere eller endre prosjektet."
  exit 1
fi

echo "🔨 Building for device..."
xcodebuild \
  -project Cohab.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS" \
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
