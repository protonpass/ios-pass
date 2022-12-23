#!/bin/bash

if [ -n "$SRCROOT" ]; then PREFIX=${SRCROOT%/*}; else PREFIX=..; fi
CONSTANTS_DIR=$PREFIX/../../../pmconstants

arr=( "$PREFIX/../../../pmconstants" "$PREFIX/../../../pmconstants" "$PREFIX/../../pmconstants" "$PREFIX/../pmconstants" "$PREFIX/pmconstants")
for item in "${arr[@]}"
do
    if [ -d "$item" ];
    then
        echo "$item directory found."
        CONSTANTS_DIR="$item"
        break
    fi
done

DATA_FILE=$CONSTANTS_DIR/ObfuscatedConstants.swift
MODULE="ProtonCore-ObfuscatedConstants"
SOURCES_DIR=$(dirname $0)/../Sources
BASE_FILE_NAME=$SOURCES_DIR/ObfuscatedConstants.base.swift
DEST_FILE_NAME=$SOURCES_DIR/ObfuscatedConstants.swift

pwd
mkdir -p $DEST_DIR
rm -f DEST_FILE_NAME

if [[ -f "$DATA_FILE" ]]; then 
    echo "$DATA_FILE was found. Creating a file with real values at $DEST_FILE_NAME"
    cp $DATA_FILE $DEST_FILE_NAME
else
    echo "warning: $DATA_FILE not found. Creating a file with empty values at $DEST_FILE_NAME"
    cp $BASE_FILE_NAME $DEST_FILE_NAME
    exit
fi
