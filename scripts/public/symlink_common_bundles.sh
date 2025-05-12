#!/bin/bash
# https://developer.apple.com/forums/thread/749265
for path in "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH"/PlugIns/*/*.bundle; do
  bundle=$(basename "$path")
  if [ -d "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/$bundle" ]; then
    >&2 echo "Stripping $path"
    rm -rf "$path"
    ln -vs "../../$bundle" "$path"
  else
    >&2 echo "Not stripping $path"
  fi
done