#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"
TMP_DIR_PATH="${SCRIPT_DIR}/../../tmp"

VERSION="0.2.1"
URL="https://github.com/protonpass/proton-pass-common/releases/download/${VERSION}/PassRustCode.swift.zip"
HASH="fe689cece6628a4194bc77b531ff0bfcd276cf92888ab1d8b10eee8e9183dedb"

if ! command -v wget &> /dev/null; then
    echo "wget is not installed, installing via Homebrew"
    brew install wget
fi

echo -e "Creating tmp directory if not exist\n"
mkdir -p $TMP_DIR_PATH

echo "Downloading artifact"
wget -N -P $TMP_DIR_PATH $URL

ARTIFACT_PATH="${TMP_DIR_PATH}/PassRustCode.swift.zip"

echo "Checksum verification for artifact"
echo -n "${HASH}  ${ARTIFACT_PATH}" | shasum -a 256 -c

echo "Unzipping artifact"
unzip -o $ARTIFACT_PATH -d $TMP_DIR_PATH

UNZIPPED_PACKAGE_PATH="${TMP_DIR_PATH}/builds/proton/clients/pass/proton-pass-common/proton-pass-mobile/iOS/PassRustCore/*"
LOCAL_PACKAGE_PATH="LocalPackages/PassRustCore"

rm -fr $LOCAL_PACKAGE_PATH
mkdir $LOCAL_PACKAGE_PATH

echo "Copying unzipped package to local package directory"
mv -f $UNZIPPED_PACKAGE_PATH $LOCAL_PACKAGE_PATH

echo "Removing unzipped package"
rm -rf "${TMP_DIR_PATH}/builds"

echo "Done! You may need to restart Xcode and clean build folder if you encounter building issues."