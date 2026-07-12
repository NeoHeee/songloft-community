#!/usr/bin/env bash
set -euo pipefail

EXPECTED_BASE64_LENGTH=5276
EXPECTED_JKS_SHA256='1691c228cc7cb5f49ca6357805e529edfd37da21c107f4138d6534011c39f2a7'
JKS_BASE64_PREFIX='/u3+7Q'

extract_value() {
  local raw="$1"
  local key="$2"
  raw="${raw//$'\r'/}"
  if [[ "$raw" == *"${key}="* ]]; then
    raw="${raw#*${key}=}"
    raw="${raw%%$'\n'*}"
  fi
  raw="${raw#\"}"
  raw="${raw%\"}"
  raw="${raw#\'}"
  raw="${raw%\'}"
  printf '%s' "$raw"
}

keystore_base64="$(extract_value "${RAW_KEYSTORE_BASE64:-}" 'ANDROID_KEYSTORE_BASE64')"
store_password="$(extract_value "${RAW_STORE_PASSWORD:-}" 'ANDROID_KEYSTORE_PASSWORD')"
release_alias="$(extract_value "${RAW_KEY_ALIAS:-}" 'ANDROID_KEY_ALIAS')"
key_password="$(extract_value "${RAW_KEY_PASSWORD:-}" 'ANDROID_KEY_PASSWORD')"

keystore_base64="$(printf '%s' "$keystore_base64" | tr -d '[:space:]')"

# JKS begins with FE ED FE ED, whose Base64 prefix is /u3+7Q.
# Some UI copy paths may prepend labels or Markdown. Recover the exact JKS payload
# from its known prefix, then cap it at the fixed Base64 length of this key file.
if [[ "$keystore_base64" == *"$JKS_BASE64_PREFIX"* ]]; then
  keystore_base64="$JKS_BASE64_PREFIX${keystore_base64#*$JKS_BASE64_PREFIX}"
fi
if (( ${#keystore_base64} >= EXPECTED_BASE64_LENGTH )); then
  keystore_base64="${keystore_base64:0:EXPECTED_BASE64_LENGTH}"
fi

test -n "$keystore_base64" || { echo '::error::ANDROID_KEYSTORE_BASE64 is empty'; exit 1; }
test -n "$store_password" || { echo '::error::ANDROID_KEYSTORE_PASSWORD is empty'; exit 1; }
test -n "$release_alias" || { echo '::error::ANDROID_KEY_ALIAS is empty'; exit 1; }
test -n "$key_password" || { echo '::error::ANDROID_KEY_PASSWORD is empty'; exit 1; }

if (( ${#keystore_base64} != EXPECTED_BASE64_LENGTH )); then
  echo "::error::Recovered Base64 length is ${#keystore_base64}; expected $EXPECTED_BASE64_LENGTH"
  exit 1
fi

keystore_path="$RUNNER_TEMP/songloft-community-release.jks"
if ! printf '%s' "$keystore_base64" | base64 --decode > "$keystore_path"; then
  echo '::error::Recovered keystore text is not valid Base64'
  exit 1
fi
chmod 600 "$keystore_path"

actual_jks_sha=$(sha256sum "$keystore_path" | awk '{print $1}')
if [[ "$actual_jks_sha" != "$EXPECTED_JKS_SHA256" ]]; then
  echo "::error::Recovered JKS SHA-256 does not match the fixed signing key"
  exit 1
fi

if ! keytool -list \
  -keystore "$keystore_path" \
  -storepass "$store_password" \
  -alias "$release_alias" \
  >/dev/null 2>&1; then
  echo '::error::Store password or key alias cannot open the fixed JKS'
  exit 1
fi

echo "Validated fixed JKS SHA-256: $actual_jks_sha"
echo "Validated signing alias: $release_alias"

echo "ANDROID_KEYSTORE_PATH=$keystore_path" >> "$GITHUB_ENV"
echo "ANDROID_KEYSTORE_PASSWORD=$store_password" >> "$GITHUB_ENV"
echo "ANDROID_KEY_ALIAS=$release_alias" >> "$GITHUB_ENV"
echo "ANDROID_KEY_PASSWORD=$key_password" >> "$GITHUB_ENV"
echo "ANDROID_REQUIRE_RELEASE_SIGNING=true" >> "$GITHUB_ENV"
