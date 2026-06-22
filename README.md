# Tor Notion Browser

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![Tor Browser](https://img.shields.io/badge/Tor%20Browser-15.0.3-7D4698?logo=tor-project)](https://www.torproject.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-linux%2Famd64-lightgrey)](https://hub.docker.com/)

![Landing Preview](assets/landing-page-tor-notion-browser.gif)
![C](assets/claude-fu-transparent.gif)


A hardened, privacy-focused Docker container that runs Tor Browser with encrypted local storage, accessible through a secure web interface. Designed for accessing Notion (or any web application) with enhanced anonymity and data protection.

This project combines the anonymity of the Tor network with encrypted-at-rest storage using gocryptfs, all accessible through a browser-based VNC interface. Your browsing data, cookies, and local files are automatically encrypted and persist across container restarts.

## Key Features

- **Tor Browser Integration** - Official Tor Browser 15.0.3 with GPG signature verification
- **Web-Based Access** - Access via any browser using noVNC over HTTPS (port 5800)
- **Encrypted Storage** - Browser profile and data encrypted at rest using gocryptfs (FUSE)
- **Multi-Layer Authentication** - VNC password + web authentication for secure access
- **DNS Leak Prevention** - All DNS queries routed through Tor (SOCKS5 remote DNS)
- **Automatic Tor Connection** - System Tor daemon with control port authentication
- **Persistent Sessions** - Encrypted data survives container restarts
- **Graceful Degradation** - Falls back to unencrypted mode if FUSE unavailable

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Container                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              jlesage/baseimage-gui (Based)                │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │  │
│  │  │   nginx     │  │    Xvnc     │  │    openbox      │    │  │
│  │  │  (noVNC)    │  │  (Display)  │  │ (Window Mgr)    │    │  │
│  │  │  :5800      │  │             │  │                 │    │  │
│  │  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘    │  │
│  │         │                │                  │             │  │
│  │         └────────────────┼──────────────────┘             │  │
│  │                          │                                │  │
│  │  ┌───────────────────────▼───────────────────────────┐    │  │
│  │  │              Tor Browser (Firefox)                │    │  │
│  │  │         Profile: /config/data/browser-profile     │    │  │
│  │  └───────────────────────┬───────────────────────────┘    │  │
│  │                          │                                │  │
│  │  ┌───────────────────────▼───────────────────────────┐    │  │
│  │  │           System Tor Daemon                       │    │  │
│  │  │     SOCKS: 127.0.0.1:9050  Control: :9051         │    │  │
│  │  └───────────────────────┬───────────────────────────┘    │  │
│  └──────────────────────────┼────────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────▼────────────────────────────────┐  │
│  │                 gocryptfs (Encrypted Volume)              │  │
│  │   Cipher: /config/cipher  ──►  Mount: /config/data        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                             │                                   │
└─────────────────────────────┼───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Host Volume     │
                    │   ./notion_data   │
                    └───────────────────┘
```

## Folder Structure

```
tor-notion-browser/
├── Dockerfile                 # Multi-stage build with GPG verification
├── docker-compose.yml         # Container orchestration with security settings
├── .gitignore                 # Excludes sensitive data and temp files
├── README.md                  # This file
├── LICENSE                    # MIT License
│
├── root/                      # Files copied into container
│   ├── etc/
│   │   ├── tor/
│   │   │   └── torrc          # Tor daemon configuration
│   │   └── services.d/
│   │       └── tor/
│   │           ├── run        # s6 service script for Tor
│   │           └── respawn    # Auto-restart marker
│   └── scripts/
│       ├── startapp.sh        # Main application launcher
│       ├── start-tor.sh       # Tor initialization script
│       └── entrypoint-wrapper.sh  # Encryption setup script
│
└── notion_data/               # Persistent data (gitignored)
    ├── cipher/                # Encrypted data (gocryptfs)
    ├── data/                  # Decrypted mount point
    │   └── browser-profile/   # Tor Browser profile
    └── tor-data/              # Tor daemon state
```

## How It Works

### Startup Sequence

1. **Container Initialization**
   - Base image supervisor loads init scripts in order

2. **Encryption Setup** (`03-encryption-setup.sh`)
   - Checks for FUSE device availability
   - If `STORAGE_PASSWORD` is set, initializes/mounts gocryptfs volume
   - Falls back to unencrypted mode if FUSE unavailable

3. **Tor Daemon Start** (`04-start-tor.sh`)
   - Creates Tor data directory with proper permissions
   - Starts system Tor daemon in background
   - Writes logs to `/config/tor-data/tor.log`

4. **Services Start**
   - Supervisor starts Xvnc, nginx (noVNC), openbox
   - Application service starts `startapp.sh`

5. **Browser Launch** (`startapp.sh`)
   - Waits for Tor proxy to be ready (port 9050)
   - Configures environment for external Tor usage
   - Sets up browser proxy preferences
   - Launches Tor Browser with Notion.so

### Data Flow

```
User Browser ──HTTPS:5800──► nginx/noVNC ──► Xvnc ──► Tor Browser
                                                           │
                                                           ▼
                                                    Tor SOCKS Proxy
                                                     (127.0.0.1:9050)
                                                           │
                                                           ▼
                                                    Tor Network
                                                           │
                                                           ▼
                                                     notion.so
```

## Installation

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- Linux host with FUSE support (for encryption)
- ~2GB disk space for image

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/TheChosenOne-start/tor-notion-browser.git
   cd tor-notion-browser
   ```

2. **Configure environment** (optional)

   Edit `docker-compose.yml` to customize passwords:
   ```yaml
   environment:
     - VNC_PASSWORD=your-vnc-password
     - WEB_AUTHENTICATION_USERNAME=admin
     - WEB_AUTHENTICATION_PASSWORD=your-web-password
     - STORAGE_PASSWORD=your-encryption-key
   ```

3. **Build and start**
   ```bash
   docker compose up -d
   ```

4. **Access the browser**

   Open https://localhost:5800 in your browser.

   Accept the self-signed certificate warning, then log in with your web credentials.

## Usage

### Accessing the Interface

1. Navigate to `https://localhost:5800`
2. Accept the self-signed SSL certificate
3. Enter web authentication credentials (if enabled)
4. You'll see the Tor Browser with Notion.so loaded
   (But honestly you can search whatever you want)

### Keyboard Shortcuts (noVNC)

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+Shift` | Open noVNC menu |
| `F8` | Toggle noVNC control bar |

### Changing the Default URL

Edit `root/scripts/startapp.sh` and change the URL:
```bash
exec ./start-tor-browser --profile "/config/data/browser-profile" "https://your-url.com"
```

NOTE: Can I prevent a company from associating or labeling AI-generated data with my personal identity?
      YES, this is the solution...

Rebuild the container after changes:
```bash
docker compose build && docker compose up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | (required) | Password for VNC connection |
| `WEB_AUTHENTICATION` | `1` | Enable web authentication (0/1) |
| `WEB_AUTHENTICATION_USERNAME` | `admin` | Web login username |
| `WEB_AUTHENTICATION_PASSWORD` | (required) | Web login password |
| `STORAGE_PASSWORD` | (optional) | Encryption key for gocryptfs |
| `USER_ID` | `1000` | UID for file ownership |
| `GROUP_ID` | `1000` | GID for file ownership |

### Encryption Modes

| STORAGE_PASSWORD | FUSE Available | Mode |
|------------------|----------------|------|
| Set | Yes | Encrypted (gocryptfs) |
| Set | No | Unencrypted (warning logged) |
| Not set | Any | Unencrypted (warning logged) |

## Docker Commands

### Build

```bash
# Build with cache
docker compose build

# Build without cache (clean rebuild)
docker compose build --no-cache
```

### Run

```bash
# Start in foreground
docker compose up

# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Maintenance

```bash
# Enter container shell
docker exec -it tor-notion-browser-tor-notion-1 sh

# Check Tor status
docker exec tor-notion-browser-tor-notion-1 cat /config/tor-data/tor.log

# View running processes
docker exec tor-notion-browser-tor-notion-1 ps aux
```

## Security Considerations

### What This Project Provides

- **Network Anonymity**: All traffic routed through Tor network
- **DNS Privacy**: DNS queries sent through Tor (no DNS leaks)
- **Data Encryption**: Local storage encrypted with gocryptfs
- **Access Control**: Multi-layer authentication (web + VNC)
- **Verified Downloads**: Tor Browser GPG signature verification
- **Host Isolation**: If FUSE is been used - Container runs privileged

### What This Project Does NOT Provide

- **End-to-End Encryption**: Data is decrypted while container runs
- **Host Isolation**: Container runs privileged (required for FUSE)
- **Traffic Analysis Protection**: Timing attacks still possible
- **Operational Security**: User behavior can still deanonymize

### Recommendations

1. **Use strong, unique passwords** for all authentication layers
2. **Don't store highly sensitive data** - encryption protects at rest, not runtime
3. **Keep the host secure** - container security depends on host security
4. **Update regularly** - rebuild periodically to get Tor Browser updates
5. **Review Tor Project guidelines** for proper anonymity practices

### Network Exposure

| Port | Protocol | Purpose | Exposure |
|------|----------|---------|----------|
| 5800 | HTTPS | noVNC Web Interface | Configurable |
| 5900 | VNC | Direct VNC (optional) | Not exposed by default |
| 9050 | SOCKS5 | Tor Proxy | Internal only |
| 9051 | TCP | Tor Control | Internal only |

## Troubleshooting

### Common Issues

#### "The proxy server is refusing connections"

**Cause**: Tor daemon not running or not ready.

**Solution**:
```bash
# Check if Tor is running
docker exec tor-notion-browser-tor-notion-1 netstat -tlnp | grep 9050

# Check Tor logs
docker exec tor-notion-browser-tor-notion-1 cat /config/tor-data/tor.log
```

#### Blank screen in browser

**Cause**: Application crashed or failed to start.

**Solution**:
```bash
# Check container logs
docker compose logs -f

# Look for error messages in app output
docker logs tor-notion-browser-tor-notion-1 2>&1 | grep -i error
```

#### "Invalid mountpoint: directory not empty"

**Cause**: Previous unclean shutdown left mount in bad state.

**Solution**:
```bash
# Stop container
docker compose down

# Clear the data directory
rm -rf ./notion_data/data/*

# Restart
docker compose up -d
```

#### Encryption not working (FUSE errors)

**Cause**: FUSE device not available or insufficient permissions.

**Solution**:
1. Ensure host has FUSE installed: `apt install fuse`
2. Verify device exists: `ls -la /dev/fuse`
3. Container must run privileged (already set in docker-compose.yml)

#### Container keeps restarting

**Cause**: Script errors or missing dependencies.

**Solution**:
```bash
# Check full logs
docker logs tor-notion-browser-tor-notion-1

# Common fix: rebuild from scratch
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Debug Mode

To enable verbose logging, add to docker-compose.yml:
```yaml
environment:
  - CONTAINER_DEBUG=1
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/TheChosenOne-start/tor-notion-browser.git
cd tor-notion-browser

# Build and test locally
docker compose build
docker compose up

# Make changes to scripts in root/
# Rebuild and test
docker compose build && docker compose up -d
```

### Code Style

- Shell scripts: Use `#!/bin/sh` for POSIX compatibility
- Use `set -e` for error handling
- Add comments for non-obvious logic
- Test changes before submitting PR

## License

My project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Tor Project](https://www.torproject.org/) - Tor Browser and network
- [jlesage/docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui) - Base image (extremely customized tho)
- [DomiStyle/docker-tor-browser](https://github.com/DomiStyle/docker-tor-browser) - Inspiration and icon
- [rfjakob/gocryptfs](https://github.com/rfjakob/gocryptfs) - Encrypted filesystem

---

**Disclaimer**: This software is provided for legitimate privacy and security purposes. Users are responsible for complying with applicable laws and terms of service. The authors are not responsible for misuse.
