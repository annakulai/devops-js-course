#!/bin/bash

DEFAULT_THRESHOLD=50

THRESHOLD="${1:-${DEFAULT_THRESHOLD}}"

if ! [[ "$THRESHOLD" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
  echo "Inputs must be a numbers"
  exit 0
fi

echo "Observing free disk space for threshold: '$THRESHOLD' %"
echo "Press CTRL+C if you want to stop..."

df -h | grep -vE '^Filesystem|tmpfs|cdrom|map' | while true; do
  read -r data
  current_used=$(echo "$data" | awk '{print $5}' | sed s/%//g)
  disk=$(echo "$data" | awk '{print $1}')

  if [ "$current_used" ] && [ "$current_used" -ge "$THRESHOLD" ]; then
    echo -e "\033[31;41mWARNING: The disk \"$disk\" has used $current_used% of total available space \033[0m"
  fi
  sleep 2
done
