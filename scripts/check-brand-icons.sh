#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "[brand-icons] ERROR: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -s "$path" ]] || fail "missing or empty file: $path"
  echo "[brand-icons] OK file: $path"
}

require_text() {
  local path="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$path" || fail "$path does not contain: $pattern"
}

require_png() {
  local path="$1"
  require_file "$path"
  local signature
  signature=$(head -c 8 "$path" | od -An -tx1 | tr -d ' \n')
  [[ "$signature" == "89504e470d0a1a0a" ]] || fail "not a PNG file: $path"
}

require_ico() {
  local path="$1"
  require_file "$path"
  local signature
  signature=$(head -c 4 "$path" | od -An -tx1 | tr -d ' \n')
  [[ "$signature" == "00000100" ]] || fail "not a Windows ICO file: $path"
}

echo '[brand-icons] Checking shared source assets...'
require_png assets/icons/app_icon.png
require_png assets/icons/app_icon_foreground.png
require_png assets/icons/app_icon_monochrome.png

echo '[brand-icons] Checking Web and PWA assets...'
require_png web/icons/Icon-192.png
require_png web/icons/Icon-512.png
require_png web/icons/Icon-maskable-192.png
require_png web/icons/Icon-maskable-512.png
require_text web/index.html 'icons/Icon-192.png?v=community-2'
require_text web/index.html 'icons/Icon-512.png?v=community-2'
require_text web/manifest.json '"name": "Songloft Community"'
require_text web/manifest.json '"theme_color": "#6D3DE7"'
if grep -Fq 'href="favicon.png"' web/index.html; then
  fail 'web/index.html still references the upstream favicon.png'
fi
if [[ -e web/favicon.png ]]; then
  fail 'stale source web/favicon.png must not be committed; build workflows create a branded fallback'
fi

echo '[brand-icons] Checking Android phone and TV assets...'
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  require_png "android/app/src/main/res/mipmap-${density}/ic_launcher.png"
  require_png "android/app/src/main/res/drawable-${density}/ic_launcher_foreground.png"
  require_png "android/app/src/main/res/drawable-${density}/ic_launcher_monochrome.png"
done
require_text android/app/src/main/AndroidManifest.xml 'android:icon="@mipmap/ic_launcher"'
require_text android/app/src/main/AndroidManifest.xml 'android:banner="@drawable/tv_banner"'
require_text android/app/src/main/res/drawable/tv_banner.xml 'android:drawable="@mipmap/ic_launcher"'
require_text android/app/src/main/res/values/strings.xml '<string name="app_name">Songloft Community</string>'

echo '[brand-icons] Checking Windows assets...'
require_ico windows/runner/resources/app_icon.ico
require_text windows/runner/Runner.rc 'IDI_APP_ICON'
require_text windows/runner/Runner.rc 'Songloft Community'

echo '[brand-icons] Checking Apple assets...'
require_png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
require_png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
require_text ios/Runner/Info.plist '<string>Songloft Community</string>'

echo '[brand-icons] Checking Linux identity...'
require_text linux/runner/my_application.cc 'Songloft Community'

echo '[brand-icons] All platform branding checks passed.'
