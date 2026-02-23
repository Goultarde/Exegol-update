
#!/bin/bash

set -e

# ───────────── CONFIG ─────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEGOL_SCRIPT="$SCRIPT_DIR/exu-server"
CRON_TMP="/tmp/crontab_check.txt"
CONTAINER_NAME="exegol-nginx"
CRON_ENTRY="0 0 * * * /usr/local/bin/exu-server --force"
#* * * * * commande
#| | | | |
#| | | | └── Jour de la semaine (0-7) (0 ou 7 = dimanche)
#| | | └──── Mois (1-12)
#| | └────── Jour du mois (1-31)
#| └──────── Heure (0-23)
#└────────── Minute (0-59)

# ───────────── OPTIONS MANAGEMENT ─────────────

NOW_MODE=false
REPO_URL=""
BUILD_PROFILE=""
UNINSTALL_MODE=false

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --now) NOW_MODE=true; shift ;;
        --uninstall) UNINSTALL_MODE=true; shift ;;
        --repo) REPO_URL="$2"; shift 2 ;;
        --profile) BUILD_PROFILE="$2"; shift 2 ;;
        -h|--help) 
            echo "Usage : $0 [--now] [--uninstall] [--repo <url>] [--profile <name>] [-h|--help]"
            echo
            echo "  --now        Run exu-server immediately after setup"
            echo "  --uninstall  Remove server configuration (Docker, crontab, binary)"
            echo "  --repo       Custom image repository URL (Repo)"
            echo "  --profile    Image profile name (e.g., light, full)"
            echo "  -h, --help   Displays this help"
            exit 0
            ;;
        *) shift ;;
    esac
done

# ───────────── COULEURS ─────────────
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }
prompt()  { echo -e "${YELLOW}[?]${RESET} $1"; }

# ───────────── Directory Preparation ─────────────

# Directories are already created in exu-server
# info "Creating directories if needed..."
# mkdir -p /exu/exegol-update-server/exu-tars
# mkdir -p /exu/exegol-update-server/exu-logs


# ───────────── SERVER UNINSTALLATION ─────────────

if $UNINSTALL_MODE; then
    info "Uninstalling server configuration..."
    
    # 1. Remove container
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
        info "Stopping and removing container $CONTAINER_NAME..."
        cd "$SCRIPT_DIR/docker" && docker compose down
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        success "Container removed: $CONTAINER_NAME"
    else
        info "No $CONTAINER_NAME container found."
    fi

    # 2. Remove executable
    if [[ -f "/usr/local/bin/exu-server" ]]; then
        info "Removing /usr/local/bin/exu-server..."
        sudo rm -f "/usr/local/bin/exu-server"
        success "Binary removed."
    fi

    # 3. Clean up crontab
    info "Cleaning up cron task..."
    crontab -l 2>/dev/null > "$CRON_TMP" || touch "$CRON_TMP"
    if grep -Fq "/usr/local/bin/exu-server" "$CRON_TMP"; then
        grep -Fv "/usr/local/bin/exu-server" "$CRON_TMP" | crontab -
        success "Cron task removed."
    else
        info "No cron task found for exu-server."
    fi
    rm -f "$CRON_TMP"

    echo
    success "✅ Uninstallation complete."
    exit 0
fi


# ───────────── Clean Previous Docker ─────────────

if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
    info "Container $CONTAINER_NAME detected. Removing..."
    docker rm -f "$CONTAINER_NAME" && success "Container removed: $CONTAINER_NAME"
fi

# ───────────── Copy exu-server to /usr/local/bin ─────────────

info "Installing exu-server to /usr/local/bin..."
if sudo cp "$EXEGOL_SCRIPT" /usr/local/bin/exu-server; then
    if [[ -n "$REPO_URL" ]]; then
        info "Updating custom Repo..."
        sudo sed -i "s|^REPO_URL=.*|REPO_URL=\"$REPO_URL\"|" /usr/local/bin/exu-server
    fi
    if [[ -n "$BUILD_PROFILE" ]]; then
        info "Updating custom Profile..."
        sudo sed -i "s|^BUILD_PROFILE=.*|BUILD_PROFILE=\"$BUILD_PROFILE\"|" /usr/local/bin/exu-server
        sudo sed -i "s|^IMAGE_NAME=.*|IMAGE_NAME=\"server\$BUILD_PROFILE\"|" /usr/local/bin/exu-server
    fi

    sudo chmod +x /usr/local/bin/exu-server
    success "exu-server installed in /usr/local/bin/exu-server"
else
    error "Error during exu-server installation"
    exit 1
fi

# ───────────── Launch Docker Compose ─────────────

info "Building and launching Nginx with Docker Compose..."
docker compose -f "$SCRIPT_DIR/docker/docker-compose.yml" up -d --build

# ───────────── Add crontab if absent ─────────────

info "Checking for exu-server cron task..."

crontab -l 2>/dev/null > "$CRON_TMP" || touch "$CRON_TMP"

if grep -Fq "$EXEGOL_SCRIPT" "$CRON_TMP"; then
    info "Cron task already present, nothing to do."
else
    echo "$CRON_ENTRY" >> "$CRON_TMP"
    crontab "$CRON_TMP"
    success "Cron task added: $CRON_ENTRY"
fi

rm -f "$CRON_TMP"

# ───────────── IMMEDIATE LAUNCH IF REQUESTED ─────────────

if $NOW_MODE; then
    echo
    info "--now option detected. Launching exu-server immediately..."
    success "✅ Setup complete. Nginx server online and exu-server automated."
    echo
    "$EXEGOL_SCRIPT" --force
else
    success "✅ Setup complete. Nginx server online and exu-server automated."
fi

