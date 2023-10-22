#!/bin/bash

path=$1
if [ -z "$1" ]; then
  path=$PWD
fi

echo "Total files count: $(find "$path" -type f | wc -l)"
