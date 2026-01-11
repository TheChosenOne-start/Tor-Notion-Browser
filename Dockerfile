# --- STAGE 1: DOWNLOAD & VERIFY (from DomiStyle) ---
FROM jlesage/baseimage-gui:ubuntu-22.04-v4 AS builder

ARG LOCALE="en-US"
ENV TOR_VERSION_X64="15.0.3"
ARG TARGETARCH

# x64 Tor Browser official build
ENV TOR_BINARY_X64="https://www.torproject.org/dist/torbrowser/${TOR_VERSION_X64}/tor-browser-linux-x86_64-${TOR_VERSION_X64}.tar.xz"
ENV TOR_SIGNATURE_X64="https://www.torproject.org/dist/torbrowser/${TOR_VERSION_X64}/tor-browser-linux-x86_64-${TOR_VERSION_X64}.tar.xz.asc"
ENV TOR_GPG_KEY_X64="https://openpgpkey.torproject.org/.well-known/openpgpkey/torproject.org/hu/kounek7zrdx745qydx6p59t9mqjpuhdf"
ENV TOR_FINGERPRINT_X64="0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290"

# Generate Tor onion favicons
ENV ONION_ICON_URL="https://raw.githubusercontent.com/DomiStyle/docker-tor-browser/master/icon.png"
RUN install_app_icon.sh "${ONION_ICON_URL}"

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    gpg \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN echo "Downloading Tor Browser for amd64" && \
    curl -sSLO "${TOR_BINARY_X64}" && \
    curl -sSLO "${TOR_SIGNATURE_X64}" && \
    echo "Verifying GPG signature" && \
    curl -sSL "${TOR_GPG_KEY_X64}" | gpg --import - && \
    gpg --output ./tor.keyring --export "${TOR_FINGERPRINT_X64}" && \
    gpgv --keyring ./tor.keyring "${TOR_SIGNATURE_X64##*/}" "${TOR_BINARY_X64##*/}" && \
    echo "Installing Tor Browser" && \
    tar --strip 1 -xvJf "${TOR_BINARY_X64##*/}" && \
    rm "${TOR_BINARY_X64##*/}" "${TOR_SIGNATURE_X64##*/}"

# --- STAGE 2: FINAL IMAGE (merged with your security features) ---
FROM jlesage/baseimage-gui:ubuntu-22.04-v4

ENV APP_NAME="Tor Notion Browser" \
    KEEP_APP_RUNNING=1 \
    SECURE_CONNECTION=1

ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # Runtime deps for Tor Browser
    file \
    libdbus-glib-1-2 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxt6 \
    libasound2 \
    # YOUR SECURITY ADDITIONS
    tor \
    gocryptfs \
  && rm -rf /var/lib/apt/lists/*

# Copy Tor Browser from builder
COPY --from=builder /app /opt/tor-browser
COPY --from=builder /opt/noVNC/app/images/icons/* /opt/noVNC/app/images/icons/
COPY --from=builder /opt/noVNC/index.html /opt/noVNC/index.html

# YOUR CUSTOM CONFIGS
COPY root/etc/tor/torrc /etc/tor/torrc
COPY root/scripts/startapp.sh /startapp.sh
COPY root/scripts/entrypoint-wrapper.sh /etc/cont-init.d/00-encryption-setup.sh

# Permissions
RUN chmod +x /startapp.sh /etc/cont-init.d/00-encryption-setup.sh && \
    chown -R 1000:1000 /opt/tor-browser

VOLUME ["/config"]
EXPOSE 5800 5900