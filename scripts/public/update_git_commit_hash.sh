#!/bin/bash

INFOPLIST_PATH="${TARGET_BUILD_DIR}/${EXECUTABLE_NAME}.app/Info.plist"

# Exit 
if [ ! -e "$INFOPLIST_PATH" ]; then
    echo "Info.plist does not exist at $INFOPLIST_PATH. Exiting." 
    exit 0
fi

# Location of PlistBuddy
PLISTBUDDY="/usr/libexec/PlistBuddy"

# Get the current git commmit hash (first 7 characters of the SHA)
COMMIT_HASH=$(git --git-dir="${PROJECT_DIR}/.git" --work-tree="${PROJECT_DIR}" rev-parse --short HEAD)

# Set the Git hash in the info plist for reference
$PLISTBUDDY -c "Set :GIT_COMMIT_HASH $COMMIT_HASH" "${INFOPLIST_PATH}"