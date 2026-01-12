#!/bin/sh
# Start Tor daemon as a background service

# Ensure data directory exists with correct permissions
# Use numeric UID 1000 since 'app' user may not exist during init
mkdir -p /config/tor-data
chown -R 1000:1000 /config/tor-data
chmod 700 /config/tor-data

echo "[tor] Starting Tor daemon..."

# Start Tor as UID 1000 (app user) in background
# Redirect output to log file to prevent blocking
su-exec 1000 /usr/sbin/tor -f /etc/tor/torrc > /config/tor-data/tor.log 2>&1 &

# Wait for Tor to be ready (check if port 9050 is listening)
for i in 1 2 3 4 5 6 7 8 9 10; do
    if netstat -tlnp 2>/dev/null | grep -q ':9050'; then
        echo "[tor] Tor is ready on port 9050"
        exit 0
    fi
    echo "[tor] Waiting for Tor to start... ($i/10)"
    sleep 2
done

echo "[tor] Warning: Tor may not have started properly"
exit 0
