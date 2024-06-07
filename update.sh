#!/bin/bash

# Define constants
GITLAB_REPO="https://gitlab.com/wsusoffline/wsusoffline"
GITLAB_API="https://gitlab.com/api/v4/projects/$(echo "$GITLAB_REPO" | grep -oE '[^/]+$')/repository/tags"
BASEPATH=$(pwd)/wsusoffline

# Ensure /temp directory exists
[ ! -d /temp ] && mkdir /temp

# Get latest tag name from GitLab
latest_tag=$(curl -s "$GITLAB_API" | jq -r '.[0].name')
echo "Latest version: $latest_tag"

# Formulate download URLs
ZIP_URL="${GITLAB_REPO}/-/archive/${latest_tag}/wsusoffline-${latest_tag}.zip"
HASH_URL="${GITLAB_REPO}/-/archive/${latest_tag}/wsusoffline-${latest_tag}_hashes.txt"

echo "Updating wsusoffline..."
cd /temp/
wget -q "$ZIP_URL"
wget -q "$HASH_URL"

# Variables for files and hashes
FILE="wsusoffline-${latest_tag}.zip"
HASH="wsusoffline-${latest_tag}_hashes.txt"

# Validate download
if [[ -f $FILE ]]; then
    SHA256=$(sha256sum /temp/$FILE | awk '{print $1}')
    if grep -q "$SHA256,$FILE" $HASH; then
        echo "Download validated"
        [[ -d wsusoffline ]] && rm -r wsusoffline
        unzip -q $FILE
        cd ..
        cp -av /temp/wsusoffline/* "$BASEPATH"
    else
        echo "Download failed"
        [[ -f /temp/$FILE ]] && rm -v /temp/$FILE
        [[ -f /temp/$HASH ]] && rm -v /temp/$HASH
        [[ -d /temp/wsusoffline ]] && rm -r /temp/wsusoffline/
    fi
fi

# Cleanup
[[ -d /temp ]] && rm -rf /temp

# Make the shell scripts executable again
find ../ -name '*.bash' -print0 | xargs -0 chmod +x
find ../ -name '*.sh' -print0 | xargs -0 chmod +x
cp -rf /wsus/preferences.bash /wsus/wsusoffline/sh/preferences.bash