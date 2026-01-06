#!/bin/bash

file="$1"

if [ -z "$file" ]; then
    echo "Error: no file specified"
    exit 1
fi

sed 's/\r//g' < "${file}" > "${file}_MOD";

mv "${file}_MOD" "$file";

echo "File ${file} fixed!"

