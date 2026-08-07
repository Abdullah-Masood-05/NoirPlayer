#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Bootstraps the ios/ platform folder on a macOS CI runner.
#
# BACKGROUND
#   Noir Player is currently Android-only. There is no ios/ directory in git
#   (it cannot be built/created on Windows without a Mac), so it is generated
#   here, on the macOS runner, before building.
#
#   The version-controlled files below survive `flutter create` (Flutter never
#   overwrites existing files) and are the source of truth for iOS settings:
#     ios/Podfile                 CocoaPods + permission_handler macros
#     ios/Runner/Info.plist       permissions, background modes, display name
#     ios/ExportOptions.plist     signing/export method for `flutter build ipa`
#
#   The script is idempotent: if a full ios/ project is ever committed, the
#   overlays are still applied on top of it.
#
# INPUT (environment)
#   IOS_BUNDLE_ID   Bundle identifier, e.g. com.yourname.noirplayer
#                   (defaults to com.example.noirPlayer if unset)
#   APPLE_TEAM_ID   Apple Developer Team ID (10 chars). Only needed to sign.
#   EXPORT_METHOD   app-store-connect | ad-hoc | development | enterprise
# ---------------------------------------------------------------------------
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
IOS_DIR="$ROOT/ios"
BUNDLE_ID="${IOS_BUNDLE_ID:-com.example.noirPlayer}"
TEAM_ID="${APPLE_TEAM_ID:-}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"

# --- 1. Generate the iOS platform scaffold (only when missing) --------------
if [ ! -f "$IOS_DIR/Runner.xcodeproj/project.pbxproj" ]; then
  echo "::group::Generating ios/ platform scaffold (flutter create)"
  flutter create --platforms=ios .
  echo "::endgroup::"
fi

if [ ! -f "$IOS_DIR/Runner.xcodeproj/project.pbxproj" ]; then
  echo "::error::ios/Runner.xcodeproj was not created. Check the 'flutter create' output above." >&2
  exit 1
fi

echo "::group::Applying iOS configuration (bundle id: $BUNDLE_ID)"

# The committed overlay files (Podfile, Runner/Info.plist) are already in
# place — `flutter create` does not overwrite existing files. Verify them:
for f in "$IOS_DIR/Podfile" "$IOS_DIR/Runner/Info.plist"; do
  if [ ! -f "$f" ]; then
    echo "::error::Missing iOS overlay file: $f. This file should be in git." >&2
    exit 1
  fi
done

# --- 2. Bundle identifier (skip the RunnerTests target) ----------------------
export BUNDLE_ID
perl -pi -e 'next if /PRODUCT_BUNDLE_IDENTIFIER = .*\.RunnerTests;/; s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $ENV{BUNDLE_ID};/g' \
  "$IOS_DIR/Runner.xcodeproj/project.pbxproj"

# --- 3. Development team (only needed for signing) ---------------------------
if [ -n "$TEAM_ID" ]; then
  export TEAM_ID
  perl -pi -e 's/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = $ENV{TEAM_ID};/g' \
    "$IOS_DIR/Runner.xcodeproj/project.pbxproj"
fi

# --- 4. Render ExportOptions.plist (used by the signed build) ----------------
export EXPORT_METHOD TEAM_ID
perl -pi -e 's/METHOD_PLACEHOLDER/$ENV{EXPORT_METHOD}/g; s/TEAM_ID_PLACEHOLDER/$ENV{TEAM_ID}/g' \
  "$IOS_DIR/ExportOptions.plist"

echo "::endgroup::"
echo "iOS bootstrap complete."
