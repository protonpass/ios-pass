#!/bin/bash -x

IFS= # Preserve new lines for "cat" command
script_path=$(dirname $0)
script_dir=$(basename ${script_path})
script_name=$(basename "$0")
base_file_name="base_swiftlint.yml"
base_content=$(cat "${script_path}/${base_file_name}")
final_content="# This file is auto-generated and should not be modified.\n# Modify instead ${script_dir}/${base_file_name}.\n# Then run ${script_dir}/${script_name}.\n${base_content}"
modules=("Client" "Core" "iOS" "macOS" "UIComponents")

for module in "${modules[@]}"
do
    echo $final_content > "${script_path}/../${module}/.swiftlint.yml"
done

# echo with colors: https://stackoverflow.com/a/57559997/2034535
echo "\033[32;1m🐶 Updated .swiftlint.yml files in all projects\033[0m"