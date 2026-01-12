#!/bin/sh
set -e

echo "[INFO] Starting Tor Browser..."

# Ensure profile directory exists
mkdir -p /config/data/browser-profile

# Use system Tor instead of bundled
export TOR_SKIP_LAUNCH=1
export TOR_SOCKS_PORT=9050
export TOR_CONTROL_PORT=9051

# Run in foreground (no --detach) so supervisor keeps it alive
cd /opt/tor-browser/Browser
exec ./firefox \
    --profile /config/data/browser-profile \
    "https://www.notion.so"