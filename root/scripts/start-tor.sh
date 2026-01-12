#!/bin/sh
# Start Tor daemon during init (before services start)
# This runs as root, but Tor runs as UID 1000

# Prepare data directory
mkdir -p /config/tor-data
chown -R 1000:1000 /config/tor-data
chmod 700 /config/tor-data

echo "[tor] Starting Tor daemon..."

# Start Tor as UID 1000 in background, output to log file (non-blocking)
su-exec 1000 /usr/sbin/tor -f /etc/tor/torrc > /config/tor-data/tor.log 2>&1 &

echo "[tor] Tor daemon started in background (PID: $!)"
exit 0
