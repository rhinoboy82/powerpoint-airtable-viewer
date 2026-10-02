#!/bin/bash
#
# Builds "Install RoomSum Add-ins.app", the Mac installer since 2026-10-02:
# universal (Apple Silicon and Intel), signed with the Developer ID
# Application certificate, notarized, stapled, and zipped for the downloads
# page. Why an app and not the installer package: mac-app/InstallRoomSum.swift.
#
#   ./build-mac-app.sh           build, sign, notarize, staple, zip
#   ./build-mac-app.sh --local   build and sign only, to try on this Mac
#
# Output, in dist-app/:
#   install-roomsum-mac.zip    copy to qa-ag/public/downloads/

set -euo pipefail
cd "$(dirname "$0")"

NAME="Install RoomSum Add-ins"
OUT="dist-app"
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
xcrun swift mac-app/make-icon.swift "$OUT/AppIcon.iconset"
iconutil -c icns "$OUT/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$OUT/AppIcon.iconset"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>com.1010ths.roomsum.installer</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 1010ths Development Corporation</string>
</dict>
</plist>
PLIST

echo "==> signing"
codesign --force --options runtime --timestamp --entitlements mac-app/InstallRoomSum.entitlements \
  --sign "$CERT" "$APP"
codesign --verify --strict --verbose=2 "$APP"

if [ "${1:-}" = "--local" ]; then
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
(cd "$OUT" && rm -f install-roomsum-mac.zip && ditto -c -k --norsrc --noextattr --keepParent "$NAME.app" install-roomsum-mac.zip)
echo "Done: $OUT/install-roomsum-mac.zip"
