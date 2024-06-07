#!/bin/bash

# Define constants
GITLAB_REPO="https://gitlab.com/wsusoffline/wsusoffline"
GITLAB_API="https://gitlab.com/api/v4/projects/$(echo "$GITLAB_REPO" | grep -oE '[^/]+$')/repository/tags"
BASEPATH=$(pwd)/wsusoffline
VERSION_FILE="${BASEPATH}/version.txt"

# Ensure /temp directory exists
[ ! -d /temp ] && mkdir /temp

# Ensure static directory exists
[ ! -d "${BASEPATH}/static" ] && mkdir -p "${BASEPATH}/static"

# Fetch the current version from GitLab
current_version=$(curl -s "https://gitlab.com/wsusoffline/wsusoffline/-/raw/master/static/SelfUpdateVersion-this.txt?ref_type=heads")

# Read the last downloaded version
last_version=$(cat "${VERSION_FILE}" 2>/dev/null)

echo "Current version online: $current_version"
echo "Last version downloaded: $last_version"

# Compare versions
if [ "$current_version" != "$last_version" ]; then
    echo "New update found. Updating wsusoffline..."

    # Get latest tag name from GitLab
    latest_tag=$(curl -s "$GITLAB_API" | jq -r '.[0].name')
    echo "Latest version by tag: $latest_tag"

    # Formulate download URLs
    ZIP_URL="${GITLAB_REPO}/-/archive/${latest_tag}/wsusoffline-${latest_tag}.zip"
    HASH_URL="${GITLAB_REPO}/-/archive/${latest_tag}/wsusoffline-${latest_tag}_hashes.txt"

    cd /temp/
    wget -q "$ZIP_URL"
    wget -q "$HASH_URL"

    # Variables for files and hashes
    FILE="wsusoffline-${latest_tag}.zip"
    HASH="wsusoffline-${latest_tag}_hashes.txt"

    # Validate download
    if [[ -f $FILE ]]; then
        SHA256=$(sha256sum $FILE | awk '{print $1}')
        if grep -q "$SHA256,$FILE" $HASH; then
            echo "Download validated"
            [[ -d wsusoffline ]] && rm -r wsusoffline
            unzip -q $FILE
            cd ..
            cp -av /temp/wsusoffline/* "$BASEPATH"
            echo $current_version > "$VERSION_FILE"
        else
            echo "Download failed"
            rm -v $FILE $HASH
            [[ -d /temp/wsusoffline ]] && rm -r /temp/wsusoffline/
        fi
    fi

    # Cleanup
    rm -rf /temp/*
else
    echo "No update required. Current version is up-to-date."
    sleep 48h
fi

# Make the shell scripts executable again
find $BASEPATH -name '*.bash' -print0 | xargs -0 chmod +x
find $BASEPATH -name '*.sh' -print0 | xargs -0 chmod +x
cp -rf /wsus/preferences.bash /wsus/wsusoffline/sh/preferences.bash
