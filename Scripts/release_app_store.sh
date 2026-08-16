#!/bin/zsh

set -euo pipefail

script_directory=${0:A:h}
repository_root=${script_directory:h}
archive_path=${ARCHIVE_PATH:-/tmp/rebody-release.xcarchive}
export_path=${EXPORT_PATH:-/tmp/rebody-release-export}
team_id=W7WQFW7K74

cd "$repository_root"

if ! security find-identity -v -p codesigning | rg -q "Apple Distribution:.*\\(${team_id}\\)"; then
  echo "OUR ENGINEERING (${team_id}) のApple Distribution証明書が見つかりません。"
  exit 1
fi

export_options=$(mktemp /tmp/rebody-export-options.XXXXXX.plist)
trap 'find "$export_options" -depth -delete 2>/dev/null || true' EXIT

cat > "$export_options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>app-store-connect</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>${team_id}</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
PLIST

xcodebuild \
  -project FutureBody.xcodeproj \
  -scheme FutureBody \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -allowProvisioningUpdates \
  -jobs 1 \
  archive

find "$export_path" -depth -delete 2>/dev/null || true
xcodebuild \
  -exportArchive \
  -archivePath "$archive_path" \
  -exportPath "$export_path" \
  -exportOptionsPlist "$export_options" \
  -allowProvisioningUpdates

ipa_path=$(find "$export_path" -maxdepth 1 -type f -name '*.ipa' -print -quit)
if [[ -z "$ipa_path" ]]; then
  echo "IPAが見つかりません。"
  exit 1
fi

echo "IPA: $ipa_path"

if [[ -n "${ASC_API_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]]; then
  xcrun altool \
    --upload-app \
    --type ios \
    --file "$ipa_path" \
    --apiKey "$ASC_API_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"
else
  echo "ASC_API_KEY_ID と ASC_ISSUER_ID が未設定のため、アップロードは行っていません。"
fi
