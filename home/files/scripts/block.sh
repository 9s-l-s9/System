#!/bin/sh
# Run with sudo
WEBSITES="youtube.com x.com zeit.de"
HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak"

# Backup original hosts file (if not already backed up)
if [ ! -f "$BACKUP_FILE" ]; then
  cp "$HOSTS_FILE" "$BACKUP_FILE"
fi

# Add blocked sites
for site in $WEBSITES; do
  if ! grep -q "127.0.0.1 $site" "$HOSTS_FILE"; then
    echo "127.0.0.1 $site" >> "$HOSTS_FILE"
    echo "Blocked: $site"
  fi
done

# Optional: Flush DNS cache (Linux)
systemd-resolve --flush-caches 2>/dev/null || echo "DNS cache flushed (if applicable)"