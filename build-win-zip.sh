#!/bin/bash
# Live Web Slide Viewer: the Windows installer as one zip, everything inside.
# Re-run after any change to install-windows.bat or manifest.xml.
set -e
cd "$(dirname "$0")"
STAGE="$(mktemp -d)/Install Live Web Slide Viewer (Windows)"
mkdir -p "$STAGE"
cp install-windows.bat manifest.xml "$STAGE/"
cat > "$STAGE/README.txt" <<'TXT'
Live Web Slide Viewer for PowerPoint (Windows)

1. Keep these files together in one folder (unzipping does that).
2. Double-click install-windows.bat.
   If Windows shows "Windows protected your PC", click "More info",
   then "Run anyway". No administrator rights are needed.
3. Close PowerPoint completely and reopen it.
4. Insert > Add-ins > My Add-ins > Live Web Slide Viewer.

Re-run the installer any time to update. Support:
https://1010thsdev.com/1010dev/slide-viewer/
TXT
rm -f install-live-web-slide-viewer-win.zip
ditto -c -k --norsrc --noextattr --keepParent "$STAGE" install-live-web-slide-viewer-win.zip
rm -rf "$(dirname "$STAGE")"
echo "Built install-live-web-slide-viewer-win.zip:"
unzip -Z1 install-live-web-slide-viewer-win.zip
