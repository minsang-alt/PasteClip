#!/bin/bash
set -euo pipefail

# PasteClip Release Build & DMG Creation Script

APP_NAME="PasteClip"
SCHEME="PasteClip"
PROJECT="PasteClip.xcodeproj"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_OUTPUT="${BUILD_DIR}/${APP_NAME}.dmg"

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Get version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/PasteClip/Info.plist")
DMG_OUTPUT="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "==> Building ${APP_NAME} v${VERSION} (Release)"

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${EXPORT_DIR}" "${DMG_DIR}"

# Generate Xcode project
echo "==> Generating Xcode project..."
cd "${PROJECT_DIR}"
xcodegen generate

# Archive
echo "==> Archiving..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    | tail -5

# Extract .app from archive
echo "==> Extracting app bundle..."
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
    # Fallback: try usr/local path
    APP_PATH="${ARCHIVE_PATH}/Products/usr/local/bin/${APP_NAME}.app"
fi

if [ ! -d "${APP_PATH}" ]; then
    echo "ERROR: Could not find ${APP_NAME}.app in archive"
    echo "Archive contents:"
    find "${ARCHIVE_PATH}/Products" -name "*.app" 2>/dev/null
    exit 1
fi

cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create symlink to /Applications in DMG staging
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
echo "==> Creating DMG..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_OUTPUT}"

# Calculate SHA256
echo ""
echo "==> Build complete!"
echo "    DMG: ${DMG_OUTPUT}"
echo "    SHA256: $(shasum -a 256 "${DMG_OUTPUT}" | awk '{print $1}')"
echo "    Size: $(du -h "${DMG_OUTPUT}" | awk '{print $1}')"
echo ""
echo "==> To create a GitHub release:"
echo "    git tag v${VERSION}"
echo "    git push origin v${VERSION}"
echo "    gh release create v${VERSION} \"${DMG_OUTPUT}\" --title \"PasteClip v${VERSION}\" --notes \"Release v${VERSION}\""
