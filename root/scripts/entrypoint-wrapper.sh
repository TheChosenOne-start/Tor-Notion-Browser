#!/usr/bin/with-contenv sh

RAW_DIR="/config/cipher"
MOUNT_DIR="/config/data"
PASSWORD_FILE="/tmp/gocryptfs.pass"

# 1. Check if FUSE is available
if [ ! -c /dev/fuse ]; then
    echo "[WARN] /dev/fuse not found. Running UNENCRYPTED mode."
    ln -s /config /config/data 2>/dev/null || true
    exit 0
fi

# 2. Check if a password is provided
if [ -z "$STORAGE_PASSWORD" ]; then
    echo "[WARN] No STORAGE_PASSWORD provided. Running UNENCRYPTED mode."
    ln -s /config /config/data 2>/dev/null || true
    exit 0
fi

echo "$STORAGE_PASSWORD" > "$PASSWORD_FILE"
mkdir -p "$RAW_DIR" "$MOUNT_DIR"

# 3. Initialize if first run
if [ ! -f "$RAW_DIR/gocryptfs.conf" ]; then
    echo "[INFO] Initializing new encrypted volume..."
    gocryptfs -init -passfile "$PASSWORD_FILE" "$RAW_DIR"
fi

# 4. Mount
echo "[INFO] Mounting encrypted volume..."
gocryptfs -passfile "$PASSWORD_FILE" "$RAW_DIR" "$MOUNT_DIR"

# Cleanup password file from memory
rm "$PASSWORD_FILE"

# Redefine the config directory for the app to use the mounted path
# (You would adjust startapp.sh to point to /config/data)