#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Change to the directory where the script is located (project root)
cd "$(dirname "$0")"

PROJECT_ROOT="$(pwd)"
BUILD_DIR="/tmp/Augus_macOS_build"

echo "🧹 Preparing a clean build environment outside of iCloud Drive to prevent code signing issues..."
# Remove the old temporary build directory if it exists
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Rsync the project to the temp directory. 
# By NOT using the -X flag, rsync will strip all extended attributes (like com.apple.FinderInfo)
# that cause the "resource fork, Finder information, or similar detritus not allowed" codesign error.
rsync -a --exclude '.git' --exclude 'build' "$PROJECT_ROOT/" "$BUILD_DIR/"

echo "🔨 Building the Augus macOS application in Release mode..."
cd "$BUILD_DIR"

# Run xcodebuild in the clean environment
xcodebuild -scheme Augus -destination 'platform=macOS' -configuration Release SYMROOT="$BUILD_DIR/build" clean build

APP_PATH="$BUILD_DIR/build/Release/Augus.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Build failed or app not found at $APP_PATH"
    exit 1
fi

INSTALL_DIR="/Applications"

# Check if we have write access to /Applications, otherwise fallback to User's Applications
if [ ! -w "$INSTALL_DIR" ]; then
    echo "⚠️  $INSTALL_DIR is not writable by the current user. Falling back to ~/Applications"
    INSTALL_DIR="$HOME/Applications"
    mkdir -p "$INSTALL_DIR"
fi

echo "📦 Installing Augus.app to $INSTALL_DIR..."

# Kill the app if it is currently running
pkill -x "Augus" || true

# Remove the old app if it exists
if [ -d "${INSTALL_DIR}/Augus.app" ]; then
    if ! rm -rf "${INSTALL_DIR}/Augus.app" 2>/dev/null; then
        echo "⚠️  Permission denied when removing existing app. Requesting administrator privileges..."
        sudo rm -rf "${INSTALL_DIR}/Augus.app"
    fi
fi

# Copy the newly built app back to the final destination
if ! cp -a "$APP_PATH" "${INSTALL_DIR}/" 2>/dev/null; then
    echo "⚠️  Permission denied when copying app. Requesting administrator privileges..."
    sudo cp -a "$APP_PATH" "${INSTALL_DIR}/"
fi

# Clean up
rm -rf "$BUILD_DIR"

echo "✨ Successfully installed Augus to ${INSTALL_DIR}/Augus.app"
