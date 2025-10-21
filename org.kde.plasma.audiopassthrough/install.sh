#!/bin/bash

# KDE Plasma Audio Pass-Through Widget Installation Script

WIDGET_ID="org.kde.plasma.audiopassthrough"
PACKAGE_DIR="package"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"

echo "Installing KDE Plasma Audio Pass-Through Widget..."

# Check if package directory exists
if [ ! -d "$PACKAGE_DIR" ]; then
    echo "Error: Package directory not found. Please run this script from the widget root directory."
    exit 1
fi

# Create installation directory
echo "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy package contents
echo "Copying widget files..."
cp -r "$PACKAGE_DIR"/* "$INSTALL_DIR/"

# Set proper permissions
echo "Setting permissions..."
find "$INSTALL_DIR" -type f -name "*.qml" -exec chmod 644 {} \;
find "$INSTALL_DIR" -type f -name "*.xml" -exec chmod 644 {} \;
find "$INSTALL_DIR" -type f -name "*.json" -exec chmod 644 {} \;

echo "Installation complete!"
echo
echo "To add the widget to your panel:"
echo "1. Right-click on your panel"
echo "2. Select 'Add Widgets...'"
echo "3. Search for 'Audio Pass-Through'"
echo "4. Drag it to your panel"
echo
echo "To configure the widget:"
echo "1. Right-click on the widget"
echo "2. Select 'Configure Audio Pass-Through...'"
echo "3. Choose your input and output devices"
echo
echo "Installation directory: $INSTALL_DIR" 