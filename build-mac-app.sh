#!/bin/bash
#
# Builds the Mac installers, one app built per product (2026-10-02):
# universal (Apple Silicon and Intel), signed with the Developer ID
# Application certificate, notarized, stapled, and zipped. Why an app and not
# an installer package or a script: mac-app/InstallRoomSum.swift.
#
#   ./build-mac-app.sh [roomsum|liveviewer]           build, sign, notarize, staple, zip
#   ./build-mac-app.sh [roomsum|liveviewer] --local   build and sign only, to try on this Mac
#
# The product defaults to roomsum. Output:
#   dist-app/roomsum/install-roomsum-mac.zip                   copy to qa-ag/public/downloads/
#   dist-app/liveviewer/install-live-web-slide-viewer-mac.zip  host on 1010thsdev.com
# The Live Viewer build carries manifest.xml inside the app.

set -euo pipefail
cd "$(dirname "$0")"

PRODUCT="roomsum"
LOCAL=""
for arg in "$@"; do
  case "$arg" in
    roomsum|liveviewer) PRODUCT="$arg" ;;
    --local) LOCAL=1 ;;
    *) echo "usage: $0 [roomsum|liveviewer] [--local]" >&2; exit 2 ;;
  esac
done

case "$PRODUCT" in
  roomsum)
    NAME="Install RoomSum Add-ins"
    BUNDLE_ID="com.1010ths.roomsum.installer"
    ZIP="install-roomsum-mac.zip"
    ICON=(RS 00BCFF 0A0A0A)
    ;;
  liveviewer)
    NAME="Install Live Web Slide Viewer"
    # The Automator installer's identifier, kept.
    BUNDLE_ID="com.1010thsdev.install-live-web-slide-viewer"
    ZIP="install-live-web-slide-viewer-mac.zip"
    ICON=(LV 2D7FF9 FFFFFF)
    ;;
esac

OUT="dist-app/$PRODUCT"
APP="$OUT/$NAME.app"
CERT="Developer ID Application: 1010ths Development Corporation (7636LY3529)"
NOTARY_PROFILE="notary-profile"
VERSION="$(date +%Y.%m.%d)"
MIN_MACOS="12.0"

rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> compiling (arm64 and x86_64, macOS $MIN_MACOS and later)"
for arch in arm64 x86_64; do
  xcrun swiftc -O -swift-version 5 -target "$arch-apple-macos$MIN_MACOS" \
    mac-app/InstallRoomSum.swift -o "$OUT/bin-$arch"
done
lipo -create "$OUT/bin-arm64" "$OUT/bin-x86_64" -output "$APP/Contents/MacOS/$NAME"
rm -f "$OUT"/bin-*

echo "==> icon"
xcrun swift mac-app/make-icon.swift "$OUT/AppIcon.iconset" "${ICON[@]}"
iconutil -c icns "$OUT/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$OUT/AppIcon.iconset"

if [ "$PRODUCT" = "liveviewer" ]; then
  echo "==> manifest (inside the app)"
  mkdir -p "$APP/Contents/Resources/manifests"
  cp manifest.xml "$APP/Contents/Resources/manifests/live-web-slide-viewer.xml"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 1010ths Development Corporation</string>
  <key>InstallerProduct</key><string>$PRODUCT</string>
</dict>
</plist>
PLIST

echo "==> signing"
codesign --force --options runtime --timestamp --entitlements mac-app/InstallRoomSum.entitlements \
  --sign "$CERT" "$APP"
codesign --verify --strict --verbose=2 "$APP"

if [ -n "$LOCAL" ]; then
  echo "Signed, not notarized: $APP. For trying on this Mac only; never publish it."
  exit 0
fi

echo "==> notarizing (this can take a few minutes)"
ditto -c -k --keepParent "$APP" "$OUT/notarize.zip"
xcrun notarytool submit "$OUT/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
rm -f "$OUT/notarize.zip"

echo "==> stapling and verifying"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl -a -vvv -t exec "$APP"

# Zipped from inside dist-app so the archive holds the app alone. The
# notarization ticket is stapled inside the app, so it travels with it.
# --norsrc --noextattr: no AppleDouble ._ entries (only macOS's local
# provenance tag), which a non-Apple unzip would leave inside the signed app.
(cd "$OUT" && rm -f "$ZIP" && ditto -c -k --norsrc --noextattr --keepParent "$NAME.app" "$ZIP")
echo "Done: $OUT/$ZIP"
