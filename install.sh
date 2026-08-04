#!/bin/bash

set -e

REPO="5hzdqd4788-afk/betterclipboard"

echo "Looking for latest release..."

URL=$(curl -s \
https://api.github.com/repos/$REPO/releases/latest \
| grep browser_download_url \
| grep BetterClipboard.zip \
| cut -d '"' -f4)

TMP=$(mktemp -d)

curl -L "$URL" -o "$TMP/BetterClipboard.zip"

unzip -q "$TMP/BetterClipboard.zip" -d "$TMP"

rm -rf "/Applications/BetterClipboard.app"

cp -R "$TMP/BetterClipboard.app" "/Applications/"

xattr -dr com.apple.quarantine "/Applications/BetterClipboard.app"

open "/Applications/BetterClipboard.app"

rm -rf "$TMP"

echo "Done."
