#!/bin/bash

# Workaround a Xcode bug that fails to build to real devices if we alter the Info.plist
# So we only update the git commit hash when building to simulators or making releases
if [[ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" || "$CONFIGURATION" == "Release"* ]]; then
    echo "Building to simulator or making a release. Updating git commit hash."
else
    echo "Building to real devices. Skip updating git commit hash."
    exit 0
fi

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