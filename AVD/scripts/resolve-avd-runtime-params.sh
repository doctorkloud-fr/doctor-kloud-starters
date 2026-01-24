#!/usr/bin/env bash
set -euo pipefail

LOCATION="${1:-northeurope}"

echo "Resolving runtime params for location=$LOCATION"

# AADLoginForWindows: take highest, then major.minor
AAD_FULL="$(az vm extension image list-versions -l "$LOCATION" -p Microsoft.Azure.ActiveDirectory -n AADLoginForWindows -o tsv | sort -V | tail -n 1)"
AAD_MM="$(echo "$AAD_FULL" | awk -F. '{print $1 "." $2}')"

# DSC: take highest, then major.minor
DSC_FULL="$(az vm extension image list-versions -l "$LOCATION" -p Microsoft.Powershell -n DSC -o tsv | sort -V | tail -n 1)"
DSC_MM="$(echo "$DSC_FULL" | awk -F. '{print $1 "." $2}')"

# DSC modulesUrl candidates (no listing, direct HEAD)
CANDIDATES=(
  "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02893.601.zip"
  "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip"
  "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02627.270.zip"
)

MODULES_URL=""
for u in "${CANDIDATES[@]}"; do
  if curl -fsI "$u" >/dev/null 2>&1; then
    MODULES_URL="$u"
    break
  fi
done

if [[ -z "$MODULES_URL" ]]; then
  echo "ERROR: No reachable Configuration_*.zip found."
  printf 'Tried:\n - %s\n' "${CANDIDATES[@]}"
  exit 1
fi

echo "AADLoginForWindows: $AAD_FULL -> $AAD_MM"
echo "DSC:              $DSC_FULL -> $DSC_MM"
echo "DSC modulesUrl:   $MODULES_URL"

echo "##vso[task.setvariable variable=aadLoginTypeHandlerVersion]$AAD_MM"
echo "##vso[task.setvariable variable=dscTypeHandlerVersion]$DSC_MM"
echo "##vso[task.setvariable variable=dscModulesUrl]$MODULES_URL"
