#!/bin/bash
#
# Slide Viewer — One-Click Installer for Mac
# Copies the manifest.xml to PowerPoint's add-in folder.
# After running this, quit and reopen PowerPoint.
#

# Get the directory where this script lives (so it finds manifest.xml next to it)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.xml"

# PowerPoint's sideload folder
WEF_DIR="$HOME/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef"

# Check that manifest.xml exists next to this script
if [ ! -f "$MANIFEST" ]; then
    echo ""
    echo "  ERROR: manifest.xml not found."
    echo "  Make sure this script is in the same folder as manifest.xml."
    echo ""
    read -p "  Press Enter to close..."
    exit 1
fi

# Create the wef folder if it doesn't exist
mkdir -p "$WEF_DIR"

# Copy the manifest
cp "$MANIFEST" "$WEF_DIR/"

echo ""
echo "  Slide Viewer installed successfully!"
echo ""
echo "  Next steps:"
echo "    1. Quit PowerPoint completely (Cmd + Q)"
echo "    2. Reopen PowerPoint"
echo "    3. Go to Home > Add-ins > Slide Viewer"
echo ""
read -p "  Press Enter to close..."
