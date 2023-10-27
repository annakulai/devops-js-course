#!/bin/bash

DEFAULT_THRESHOLD=50
THRESHOLD="${1:-${DEFAULT_THRESHOLD}}"

if ! [[ "$THRESHOLD" =~ ^[0-9]{1,2}$ ]]; then
  echo "Inputs must be a numbers and less 100%"
  exit 0
fi

echo "Monitoring free disk space for threshold (default: ${DEFAULT_THRESHOLD}%): $THRESHOLD%"
echo "Press CTRL+C if you want to stop..."

df -Ph | grep -vE '^Filesystem|tmpfs|cdrom|map' | awk '{ print $5,$1 }' | while true; do
  read -r data
  current_used=$(echo $data | awk '{print $1}' | sed s/%//g)

  if [ "$data" ] && [ $current_used -ge $THRESHOLD ]; then
    partition=$(echo $data | awk '{print $2}')
    echo -e "\033[31;41mWARNING: The partition \"$partition\" has used $current_used% of available space \033[0m"
  fi
  sleep 2
done
