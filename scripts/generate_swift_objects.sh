#!/bin/sh

declare -a proto_file_names=(
                            "item_v1.proto"
                            "label_v1.proto"
                            "vault_v1.proto"
                            )
script_path=$(dirname $0)
proto_files_dir="${script_path}/../contents-proto-definition/protos"
output_dir="${script_path}/../Protobuf Objects"

# Create output_dir if not exist
mkdir -p $output_dir

for file_name in "${proto_file_names[@]}"
do
    echo "Generating swift objects based on $file_name"
    success=$(protoc $file_name --swift_out="${output_dir}" --swift_opt=Visibility=Public --proto_path="${proto_files_dir}")
    if (( $? == 0 )); then
    echo "\033[32;1mDone\033[0m"
  else
    echo "\033[1;31mFailed\033[0m"
  fi
done