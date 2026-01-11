#!/bin/sh
set -e

echo "[INFO] Starting Tor Browser..."

export TOR_SKIP_LAUNCH=1
export TOR_SOCKS_PORT=9050
export TOR_CONTROL_PORT=9051

exec /opt/tor-browser/Browser/start-tor-browser \
    --detach \
    --profile /config/data/browser-profile \
    "https://www.notion.so"