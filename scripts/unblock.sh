#!/bin/sh
# Restore the original hosts file
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak"

if [ -f "$BACKUP_FILE" ]; then
  cp "$BACKUP_FILE" "$HOSTS_FILE"
  echo "Sites unblocked."
else
  echo "No backup found. Manually remove entries from $HOSTS_FILE."
fi