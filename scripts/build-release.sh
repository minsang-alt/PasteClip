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
SHA256=$(shasum -a 256 "${DMG_OUTPUT}" | awk '{print $1}')
DMG_SIZE=$(stat -f%z "${DMG_OUTPUT}")

echo ""
echo "==> Build complete!"
echo "    DMG: ${DMG_OUTPUT}"
echo "    SHA256: ${SHA256}"
echo "    Size: $(du -h "${DMG_OUTPUT}" | awk '{print $1}')"

# EdDSA signing with Sparkle
SIGN_UPDATE="${BUILD_DIR}/sign_update"
SPARKLE_PKG_DIR=$(find "${PROJECT_DIR}/.build" "${HOME}/Library/Developer/Xcode/DerivedData" -path "*/Sparkle.framework" -maxdepth 10 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)

if [ -z "${SPARKLE_PKG_DIR}" ]; then
    # Try SPM .build directory
    SIGN_UPDATE_SEARCH=$(find "${PROJECT_DIR}" -name "sign_update" -path "*Sparkle*" 2>/dev/null | head -1 || true)
    if [ -n "${SIGN_UPDATE_SEARCH}" ]; then
        SIGN_UPDATE="${SIGN_UPDATE_SEARCH}"
    fi
fi

if command -v "${SIGN_UPDATE}" &>/dev/null || [ -x "${SIGN_UPDATE}" ]; then
    echo ""
    echo "==> Signing DMG with EdDSA..."
    ED_SIGNATURE=$("${SIGN_UPDATE}" "${DMG_OUTPUT}" 2>&1 | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/' || true)

    if [ -n "${ED_SIGNATURE}" ]; then
        echo "    EdDSA Signature: ${ED_SIGNATURE}"

        # Update appcast.xml
        APPCAST="${PROJECT_DIR}/appcast.xml"
        if [ -f "${APPCAST}" ]; then
            echo "==> Updating appcast.xml..."
            sed -i '' "s|sparkle:edSignature=\"[^\"]*\"|sparkle:edSignature=\"${ED_SIGNATURE}\"|" "${APPCAST}"
            sed -i '' "s|length=\"[^\"]*\"|length=\"${DMG_SIZE}\"|" "${APPCAST}"
            echo "    appcast.xml updated with signature and file size"
        fi
    else
        echo "    WARNING: Could not extract EdDSA signature. Run manually:"
        echo "    sign_update \"${DMG_OUTPUT}\""
    fi
else
    echo ""
    echo "==> Sparkle sign_update not found. To sign the DMG:"
    echo "    1. Build the project first to download Sparkle"
    echo "    2. Find sign_update in Sparkle's bin/ directory"
    echo "    3. Run: sign_update \"${DMG_OUTPUT}\""
fi

echo ""
echo "==> To create a GitHub release:"
echo "    git tag v${VERSION}"
echo "    git push origin v${VERSION}"
echo "    gh release create v${VERSION} \"${DMG_OUTPUT}\" --title \"PasteClip v${VERSION}\" --notes \"Release v${VERSION}\""
