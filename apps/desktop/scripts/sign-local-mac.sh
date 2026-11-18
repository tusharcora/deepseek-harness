#!/bin/sh
# Re-sign a local (unsigned) Mac build with a code-signing identity from the login keychain, then wrap it in a DMG.
# A real identity keeps the app's code identity the same across rebuilds, so macOS remembers privacy permissions
# (Documents, Desktop, Full Disk Access) instead of asking again. Entitlements and identifiers are kept as built.
#
#   apps/desktop/scripts/sign-local-mac.sh "path/to/DeepSeek Harness.app" [out-dir]
#
# DSH_LOCAL_SIGN_IDENTITY picks the identity; default: the first "Apple Development" one.
# shortcut: not notarized, so it is for this Mac only; release builds use the signed packaging path.
set -eu
APP=${1:?usage: sign-local-mac.sh <app> [out-dir]}
OUT=${2:-$(dirname "$APP")}
ID=${DSH_LOCAL_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -1)}
[ -n "$ID" ] || { echo "sign-local-mac: no code-signing identity; set DSH_LOCAL_SIGN_IDENTITY" >&2; exit 1; }
codesign --force --deep --sign "$ID" --options runtime --timestamp=none \
  --preserve-metadata=entitlements,identifier,flags "$APP"
codesign --verify --deep --strict "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG="$OUT/deepseek-harness-$VERSION-mac-$(uname -m)-dev-signed.dmg"
hdiutil create -quiet -volname "DeepSeek Harness" -srcfolder "$APP" -ov -format UDZO "$DMG"
echo "signed with: $ID"
echo "$DMG"
