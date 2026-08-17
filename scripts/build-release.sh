#!/bin/bash
set -euo pipefail

# PasteClip Release Build & DMG Creation Script

# --- Signing configuration ---------------------------------------------------
# Default: ad-hoc signing (pre-Apple-Developer-Program fallback).
# For a notarized Developer ID release, run:
#   SIGN_IDENTITY="Developer ID Application: <Name> (<TEAMID>)" bash scripts/build-release.sh
# One-time setup for notarization credentials (after enrolling):
#   xcrun notarytool store-credentials "pasteclip-notary" \
#     --apple-id <apple-id-email> --team-id <TEAMID> --password <app-specific-password>
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-pasteclip-notary}"
# -----------------------------------------------------------------------------

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
# Distribution entitlements: intentionally NO app sandbox.
# Shipped builds have always run unsandboxed (data lives in
# ~/Library/Application Support/com.minsang.PasteClip). Enabling the sandbox
# here would silently move user data into a container and "lose" history.
# The sandboxed variant is reserved for the future Mac App Store target.
DIST_ENTITLEMENTS="${PROJECT_DIR}/PasteClip/PasteClip-Distribution.entitlements"

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

if [ "${SIGN_IDENTITY}" != "-" ]; then
    echo "==> Release mode: Developer ID signing + notarization"
    echo "    Identity: ${SIGN_IDENTITY}"
    RUNTIME_FLAGS=(--options runtime --timestamp)
else
    echo "==> Release mode: ad-hoc signing (NOT notarized)"
    RUNTIME_FLAGS=()
fi

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

# Re-sign everything (inside-out order)
# Sparkle XPC services must be re-signed so they share the same signing authority
# as the host app, otherwise XPC connection fails during updates
echo "==> Re-signing (inside-out)..."
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${DMG_DIR}/${APP_NAME}.app/Contents/Info.plist")
SPARKLE_FW="${DMG_DIR}/${APP_NAME}.app/Contents/Frameworks/Sparkle.framework/Versions/B"

# Sign inner components first (inside-out). --preserve-metadata=entitlements
# keeps Sparkle's own XPC entitlements intact (per Sparkle signing docs).
for xpc in "${SPARKLE_FW}/XPCServices/"*.xpc; do
    codesign --force --sign "${SIGN_IDENTITY}" ${RUNTIME_FLAGS[@]+"${RUNTIME_FLAGS[@]}"} --preserve-metadata=entitlements "$xpc"
done
codesign --force --sign "${SIGN_IDENTITY}" ${RUNTIME_FLAGS[@]+"${RUNTIME_FLAGS[@]}"} "${SPARKLE_FW}/Autoupdate"
codesign --force --sign "${SIGN_IDENTITY}" ${RUNTIME_FLAGS[@]+"${RUNTIME_FLAGS[@]}"} "${SPARKLE_FW}/Updater.app"
codesign --force --sign "${SIGN_IDENTITY}" ${RUNTIME_FLAGS[@]+"${RUNTIME_FLAGS[@]}"} "${DMG_DIR}/${APP_NAME}.app/Contents/Frameworks/Sparkle.framework"

if [ "${SIGN_IDENTITY}" != "-" ]; then
    # Developer ID: standard designated requirement (cert chain + identifier)
    # is stable across versions, so no custom DR needed. Explicit distribution
    # entitlements prevent the archive's dev entitlements from leaking in.
    codesign --force --sign "${SIGN_IDENTITY}" "${RUNTIME_FLAGS[@]}" \
        --entitlements "${DIST_ENTITLEMENTS}" \
        "${DMG_DIR}/${APP_NAME}.app"
else
    # Ad-hoc: identifier-based designated requirement so Sparkle updates keep
    # matching the installed app's DR across versions.
    codesign --force --sign - --requirements "=designated => identifier \"${BUNDLE_ID}\"" \
        --entitlements "${DIST_ENTITLEMENTS}" \
        "${DMG_DIR}/${APP_NAME}.app"
fi

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

# Developer ID: sign the DMG, notarize, and staple BEFORE hashing/EdDSA-signing
# (stapling mutates the DMG bytes, so SHA256 and sparkle:edSignature must be
# computed afterwards).
if [ "${SIGN_IDENTITY}" != "-" ]; then
    echo "==> Signing DMG with Developer ID..."
    codesign --force --sign "${SIGN_IDENTITY}" --timestamp "${DMG_OUTPUT}"

    echo "==> Submitting to Apple notary service (this can take a few minutes)..."
    if ! xcrun notarytool submit "${DMG_OUTPUT}" --keychain-profile "${NOTARY_PROFILE}" --wait; then
        echo "    FATAL: notarization failed or was rejected."
        echo "    Inspect with: xcrun notarytool log <submission-id> --keychain-profile ${NOTARY_PROFILE}"
        exit 1
    fi

    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "${DMG_OUTPUT}"

    echo "==> Gatekeeper assessment..."
    if ! spctl --assess --type open --context context:primary-signature -v "${DMG_OUTPUT}"; then
        echo "    FATAL: Gatekeeper rejected the stapled DMG"
        exit 1
    fi
    echo "    OK: notarized and stapled"
fi

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

# Check 2b: Developer ID builds must carry the Developer ID authority
if [ "${SIGN_IDENTITY}" != "-" ]; then
    AUTH_OUTPUT=$(codesign -d -vv "${VERIFY_MOUNT}/${APP_NAME}.app" 2>&1)
    if ! echo "${AUTH_OUTPUT}" | grep -q "Authority=Developer ID Application"; then
        echo "    FATAL: app inside DMG is not signed with a Developer ID certificate"
        hdiutil detach "${VERIFY_MOUNT}" -quiet
        exit 1
    fi
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
    SIGN_FAILED=false
    if ! SIGN_OUTPUT=$("${SIGN_UPDATE}" "${DMG_OUTPUT}" 2>&1); then
        if [ "${SIGN_IDENTITY}" = "-" ] && echo "${SIGN_OUTPUT}" | grep -q "Signing key not found"; then
            SIGN_FAILED=true
            echo "    WARNING: Sparkle signing key not configured; continuing ad-hoc build"
            echo "    sign_update output: ${SIGN_OUTPUT}"
        else
            echo "    FATAL: Sparkle EdDSA signing failed"
            echo "    sign_update output: ${SIGN_OUTPUT}"
            exit 1
        fi
    fi
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
    elif [ "${SIGN_IDENTITY}" != "-" ]; then
        echo "    FATAL: Could not extract Sparkle EdDSA signature"
        echo "    sign_update output: ${SIGN_OUTPUT}"
        exit 1
    elif [ "${SIGN_FAILED}" = false ]; then
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
