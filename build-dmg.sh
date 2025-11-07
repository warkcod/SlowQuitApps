#!/bin/bash

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "  SlowQuitApps DMG Builder v1.0"
echo "================================================================================"

# Resolve version info
VERSION=$(grep -A 1 "CFBundleShortVersionString" SlowQuitApps/SlowQuitApps-Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
TIMESTAMP=$(date +%Y%m%d)
DMG_NAME="SlowQuitApps-v${VERSION}-Release.dmg"

echo -e "${BLUE}[INFO]${NC} Project: SlowQuitApps"
echo -e "${BLUE}[INFO]${NC} Version: ${VERSION}"
echo -e "${BLUE}[INFO]${NC} Configuration: Release"
echo -e "${BLUE}[INFO]${NC} Timestamp: ${TIMESTAMP}"
echo -e "${BLUE}[INFO]${NC} Output DMG: ${DMG_NAME}"
echo ""

# Validate project files
echo -e "${BLUE}[INFO]${NC} Validating project files..."
if [ ! -f "SlowQuitApps.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}[ERROR]${NC} project.pbxproj not found!"
    exit 1
fi
echo -e "${GREEN}[INFO]${NC} Project validation passed ✓"
echo ""

# Clean leftover builds
echo -e "${BLUE}[INFO]${NC} Cleaning previous builds..."
rm -rf build/
rm -rf dmgs/
rm -rf dmg_final_*
echo -e "${GREEN}[INFO]${NC}   Cleaned DerivedData"
echo -e "${GREEN}[INFO]${NC}   Cleaned temporary files"
echo ""

# Build archive
echo -e "${BLUE}[INFO]${NC} Building archive (Release)..."
ARCHIVE_PATH="build/SlowQuitApps.xcarchive"
xcodebuild -project SlowQuitApps.xcodeproj -scheme SlowQuitApps -configuration Release clean archive -archivePath "${ARCHIVE_PATH}"
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Build failed!"
    exit 1
fi
echo -e "${GREEN}[INFO]${NC} Build completed ✓"
echo ""

# Locate .app bundles
echo -e "${BLUE}[INFO]${NC} Extracting app bundles..."
APP_PATH="${ARCHIVE_PATH}/Products/Applications/SlowQuitApps.app"
LAUNCHER_PATH="${APP_PATH}/Contents/Library/LoginItems/SlowQuitAppsLauncher.app"

if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}[ERROR]${NC} App bundle not found at ${APP_PATH}"
    exit 1
fi

if [ ! -d "${LAUNCHER_PATH}" ]; then
    echo -e "${RED}[ERROR]${NC} Launcher bundle not found at ${LAUNCHER_PATH}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} App bundles ready ✓"
echo ""

# Prepare DMG payload
echo -e "${BLUE}[INFO]${NC} Creating DMG..."
DMG_DIR="dmg_final_${TIMESTAMP}"
mkdir -p "${DMG_DIR}"

DMG_APP_PATH="${DMG_DIR}/SlowQuitApps.app"
cp -R "${APP_PATH}" "${DMG_APP_PATH}"

# Ad-hoc sign so SMAppService accepts the helper
if command -v codesign >/dev/null 2>&1; then
    echo -e "${BLUE}[INFO]${NC} Ad-hoc signing SlowQuitApps.app for SMAppService compatibility..."
    if codesign --force --deep --options runtime --sign - "${DMG_APP_PATH}" >/tmp/sqa-codesign.log 2>&1; then
        echo -e "${GREEN}[INFO]${NC} Code signing completed ✓"
    else
        echo -e "${YELLOW}[WARN]${NC} codesign failed, see /tmp/sqa-codesign.log (SMAppService may reject unsigned builds)"
    fi
else
    echo -e "${YELLOW}[WARN]${NC} codesign tool not found; login item registration may fail on macOS 13+"
fi

# Add Applications symlink for drag-and-drop
if [ ! -e "${DMG_DIR}/Applications" ]; then
    ln -s /Applications "${DMG_DIR}/Applications"
fi

# Create upgrade helper app (AppleScript wrapper around shell script)
UPGRADE_APP="${DMG_DIR}/Upgrade SlowQuitApps.app"
cat <<'OSA' > /tmp/UpgradeSlowQuitApps.applescript
on run
    set helperPath to POSIX path of ((path to me as text) & "Contents:Resources:upgrade-helper.sh")
    do shell script "/bin/bash " & quoted form of helperPath with administrator privileges
end run
OSA
osacompile -o "${UPGRADE_APP}" /tmp/UpgradeSlowQuitApps.applescript >/dev/null 2>&1
rm -f /tmp/UpgradeSlowQuitApps.applescript

mkdir -p "${UPGRADE_APP}/Contents/Resources"
cat <<'SCRIPT' > "${UPGRADE_APP}/Contents/Resources/upgrade-helper.sh"
#!/bin/bash
set -euo pipefail

APP_NAME="SlowQuitApps.app"
DMG_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC_PATH="${DMG_DIR}/${APP_NAME}"
DST_PATH="/Applications/${APP_NAME}"
CONSOLE_USER=$(stat -f '%Su' /dev/console)
if [ -z "$CONSOLE_USER" ] || [ "$CONSOLE_USER" = "root" ]; then
    echo "Unable to determine the signed-in user. Please run while logged into the desktop."
    exit 1
fi
CONSOLE_UID=$(id -u "$CONSOLE_USER")

echo "== SlowQuitApps Upgrade Assistant =="
echo ""
echo "Stopping running instances..."
sudo -u "$CONSOLE_USER" defaults write com.dteoh.SlowQuitApps disableAutostart -bool YES >/dev/null 2>&1 || true
pkill -x SlowQuitApps >/dev/null 2>&1 || true
pkill -x SlowQuitAppsLauncher >/dev/null 2>&1 || true
launchctl bootout gui/${CONSOLE_UID}/com.dteoh.SlowQuitAppsLauncher >/dev/null 2>&1 || true

echo ""
echo "Copying new version to /Applications (password might be required)..."
rm -rf "$DST_PATH"
ditto "$SRC_PATH" "$DST_PATH"

echo ""
echo "Relaunching SlowQuitApps..."
sudo -u "$CONSOLE_USER" open "$DST_PATH"

echo ""
echo "Upgrade complete. You can re-enable auto-start from SlowQuitApps if needed."
SCRIPT
chmod +x "${UPGRADE_APP}/Contents/Resources/upgrade-helper.sh"

# Generate textual install instructions
cat <<'DOC' > "${DMG_DIR}/Install Instructions.txt"
SlowQuitApps Installation & Upgrade Guide
=========================================

Install:
1. Drag "SlowQuitApps.app" onto the "Applications" symlink.
2. Launch the app, grant Accessibility permissions, and enable auto-start if desired.

Upgrade:
1. Double-click "Upgrade SlowQuitApps.app". It stops running helpers, copies this build into /Applications (macOS may prompt for your password), and relaunches the updated app.
2. Alternatively, disable SlowQuitAppsLauncher in System Settings → General → Login Items, quit SlowQuitApps, replace the .app manually, then re-enable auto-start.
DOC

# Build DMG
DMG_PATH="dmg_final_${TIMESTAMP}"
hdiutil create -srcfolder "${DMG_PATH}" -volname "SlowQuitApps" -ov -format UDZO "${DMG_NAME}"
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} DMG creation failed!"
    exit 1
fi

# Generate checksums
echo ""
echo -e "${BLUE}[INFO]${NC} Generating checksums..."
MD5=$(md5 -q "${DMG_NAME}")
CRC32=$(crc32 "${DMG_NAME}")

echo -e "${GREEN}[INFO]${NC} DMG created: ${DMG_NAME}"
echo -e "${GREEN}[INFO]${NC} Size: $(du -h "${DMG_NAME}" | cut -f1)"
echo -e "${GREEN}[INFO]${NC} MD5: ${MD5}"
echo -e "${GREEN}[INFO]${NC} CRC32: ${CRC32}"
echo ""

echo "================================================================================"
echo -e "${GREEN}  DMG build completed successfully!${NC}"
echo "================================================================================"
echo "Output: ${DMG_NAME}"
echo "Checksum: ${CRC32}"
echo ""

exit 0
