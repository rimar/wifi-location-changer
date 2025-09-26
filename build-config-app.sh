#!/bin/bash

# Build script for LocationChangerConfig app
set -e

echo "Building LocationChangerConfig app..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Navigate to the app directory
cd LocationChangerConfig

# Build the app
echo "Building app..."
xcodebuild -project LocationChangerConfig.xcodeproj \
           -scheme LocationChangerConfig \
           -configuration Release \
           -derivedDataPath build \
           build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Copy the app to the main directory
    APP_PATH="build/Build/Products/Release/LocationChangerConfig.app"
    if [ -d "$APP_PATH" ]; then
        cp -R "$APP_PATH" ../
        echo "App copied to main directory: LocationChangerConfig.app"
        echo ""
        echo "To run the app:"
        echo "  open LocationChangerConfig.app"
        echo ""
        echo "To install the app system-wide:"
        echo "  sudo cp -R LocationChangerConfig.app /Applications/"
    else
        echo "Error: App bundle not found at expected location"
        exit 1
    fi
else
    echo "Build failed!"
    exit 1
fi

# Clean up build directory
rm -rf build

echo "Done!"
