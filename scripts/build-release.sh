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
    CODE_SIGNING_ALLOWED=YES \
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

# Re-sign with stable designated requirement (identifier-based, not cdhash-based)
# This ensures Sparkle can validate updates between different ad-hoc signed builds
echo "==> Re-signing with stable designated requirement..."
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${DMG_DIR}/${APP_NAME}.app/Contents/Info.plist")
codesign --force --sign - --requirements "=designated => identifier \"${BUNDLE_ID}\"" "${DMG_DIR}/${APP_NAME}.app"

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

# Verify code signing inside DMG
echo "==> Verifying code signing inside DMG..."
VERIFY_MOUNT="${BUILD_DIR}/verify_mount"
mkdir -p "${VERIFY_MOUNT}"
hdiutil attach "${DMG_OUTPUT}" -nobrowse -mountpoint "${VERIFY_MOUNT}" -quiet

VERIFY_OUTPUT=$(codesign -d -v "${VERIFY_MOUNT}/${APP_NAME}.app" 2>&1)
VERIFY_ID=$(echo "${VERIFY_OUTPUT}" | grep "^Identifier=" | head -1 | sed 's/^Identifier=//')
VERIFY_FLAGS=$(echo "${VERIFY_OUTPUT}" | grep "^CodeDirectory" || true)

# Check 1: Must have proper bundle identifier (not just binary name)
if [ "${VERIFY_ID}" != "com.minsang.PasteClip" ]; then
    echo "    FATAL: DMG app has wrong identifier: '${VERIFY_ID}' (expected 'com.minsang.PasteClip')"
    hdiutil detach "${VERIFY_MOUNT}" -quiet
    exit 1
fi

# Check 2: Must not be linker-signed (which means re-sign didn't apply)
if echo "${VERIFY_FLAGS}" | grep -q "linker-signed"; then
    echo "    FATAL: DMG app is only linker-signed (re-sign was not applied)"
    hdiutil detach "${VERIFY_MOUNT}" -quiet
    exit 1
fi

# Check 3: Deep verification
DEEP_OUTPUT=$(codesign -vvv --deep "${VERIFY_MOUNT}/${APP_NAME}.app" 2>&1)
if ! echo "${DEEP_OUTPUT}" | grep -q "valid on disk"; then
    echo "    FATAL: DMG app failed deep code signing verification"
    echo "    ${DEEP_OUTPUT}"
    hdiutil detach "${VERIFY_MOUNT}" -quiet
    exit 1
fi

hdiutil detach "${VERIFY_MOUNT}" -quiet
echo "    ✓ Code signing verified (id=${VERIFY_ID}, deep validation passed)"

# Calculate SHA256
SHA256=$(shasum -a 256 "${DMG_OUTPUT}" | awk '{print $1}')
DMG_SIZE=$(stat -f%z "${DMG_OUTPUT}")

echo ""
echo "==> Build complete!"
echo "    DMG: ${DMG_OUTPUT}"
echo "    SHA256: ${SHA256}"
echo "    Size: $(du -h "${DMG_OUTPUT}" | awk '{print $1}')"

# EdDSA signing with Sparkle
SIGN_UPDATE=$(find "${HOME}/Library/Developer/Xcode/DerivedData" "${PROJECT_DIR}/.build" -name "sign_update" -path "*/Sparkle/bin/*" 2>/dev/null | head -1 || true)

if [ -x "${SIGN_UPDATE}" ]; then
    echo ""
    echo "==> Signing DMG with EdDSA..."
    SIGN_OUTPUT=$("${SIGN_UPDATE}" "${DMG_OUTPUT}" 2>&1)
    ED_SIGNATURE=$(echo "${SIGN_OUTPUT}" | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/' || true)

    if [ -n "${ED_SIGNATURE}" ]; then
        echo "    EdDSA Signature: ${ED_SIGNATURE}"

        # Update appcast.xml — only the FIRST occurrence (current version)
        APPCAST="${PROJECT_DIR}/appcast.xml"
        if [ -f "${APPCAST}" ]; then
            echo "==> Updating appcast.xml (first item only)..."
            awk -v sig="${ED_SIGNATURE}" -v len="${DMG_SIZE}" '
                BEGIN { sig_done=0; len_done=0 }
                !sig_done && /sparkle:edSignature=/ {
                    sub(/sparkle:edSignature="[^"]*"/, "sparkle:edSignature=\"" sig "\"")
                    sig_done=1
                }
                !len_done && /length=/ {
                    sub(/length="[^"]*"/, "length=\"" len "\"")
                    len_done=1
                }
                { print }
            ' "${APPCAST}" > "${APPCAST}.tmp" && mv "${APPCAST}.tmp" "${APPCAST}"
            echo "    appcast.xml updated with signature and file size"
        fi
    else
        echo "    WARNING: Could not extract EdDSA signature"
        echo "    sign_update output: ${SIGN_OUTPUT}"
    fi
else
    echo ""
    echo "==> Sparkle sign_update not found. Build the project first to download Sparkle."
fi

echo ""
echo "==> To create a GitHub release:"
echo "    git tag v${VERSION}"
echo "    git push origin v${VERSION}"
echo "    gh release create v${VERSION} \"${DMG_OUTPUT}\" --title \"PasteClip v${VERSION}\" --notes \"Release v${VERSION}\""
