#!/bin/bash

# ────────────── COULEURS ──────────────
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }
prompt()  { echo -ne "${YELLOW}[?]${RESET} $1"; }

# ────────────── EXU-CLIENT INSTALLATION ──────────────

info "Installing exu-client..."
sudo cp $(dirname "$0")/exu-client /usr/local/bin/exu-client
sudo chmod +x /usr/local/bin/exu-client
success "exu-client installed in /usr/local/bin/"

# ────────────── HOSTS CONFIGURATION ──────────────

prompt "Exegol-update server IP address (leave empty to ignore): "
read -r SERVER_IP

if [[ -n "$SERVER_IP" ]]; then
    # Basic IP validation
    if [[ "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        info "Adding entry to /etc/hosts..."
        
        # Check if entry already exists
        if grep -q "exegol.update" /etc/hosts; then
            info "The 'exegol.update' entry already exists in /etc/hosts"
            prompt "Do you want to replace it? (y/N): "
            read -r REPLACE
            if [[ "$REPLACE" =~ ^[Yy]$ ]]; then
                # Remove old entry
                sudo sed -i '/exegol.update/d' /etc/hosts
                success "Old entry removed"
            else
                info "Entry kept, no changes made"
                exit 0
            fi
        fi
        
        # Add new entry
        echo "$SERVER_IP exegol.update" | sudo tee -a /etc/hosts > /dev/null
        success "Entry added: $SERVER_IP exegol.update"
        info "You can now use: exu-client --server=http://exegol.update:\$PORT"
    else
        error "Invalid IP address format. Use format: 192.168.1.100"
        exit 1
    fi
else
    info "No IP address provided, /etc/hosts not modified"
fi

success "Installation complete!"
