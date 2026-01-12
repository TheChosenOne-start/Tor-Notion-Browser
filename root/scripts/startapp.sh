#!/bin/sh
set -e

echo "[INFO] Starting Tor Browser..."

# Wait for Tor to be ready (started by s6 service)
echo "[INFO] Waiting for Tor proxy to be ready..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    if netstat -tlnp 2>/dev/null | grep -q ':9050'; then
        echo "[INFO] Tor is ready on port 9050"
        break
    fi
    echo "[INFO] Waiting for Tor... ($i/20)"
    sleep 2
done

# Ensure profile directory exists
mkdir -p /config/data/browser-profile

# Use system Tor instead of bundled
export TOR_SKIP_LAUNCH=1
export TOR_SOCKS_PORT=9050
export TOR_CONTROL_PORT=9051
export TOR_CONTROL_COOKIE_AUTH_FILE="/config/tor-data/control_auth_cookie"

# On first run, set essential Tor proxy prefs (fallback if Tor Launcher fails)
if [ ! -f "/config/data/browser-profile/user.js" ]; then
    cat << EOF > "/config/data/browser-profile/user.js"
user_pref("network.proxy.type", 1);
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 9050);
user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.proxy.socks_version", 5);
user_pref("extensions.torlauncher.control_host", "127.0.0.1");
user_pref("extensions.torlauncher.control_port", 9051);
user_pref("extensions.torlauncher.prompt_at_startup", false);
EOF
fi

# Run via wrapper script for proper initialization
cd /opt/tor-browser/Browser
exec ./start-tor-browser --profile "/config/data/browser-profile" "https://www.notion.so"
