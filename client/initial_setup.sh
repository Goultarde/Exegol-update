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

# ────────────── INSTALLATION EXU-CLIENT ──────────────

info "Installation d'exu-client..."
sudo cp $(dirname "$0")/exu-client /usr/local/bin/exu-client
sudo chmod +x /usr/local/bin/exu-client
success "exu-client installé dans /usr/local/bin/"

# ────────────── CONFIGURATION HOSTS ──────────────

prompt "Adresse IP du serveur Exegol-update (laissez vide pour ignorer) : "
read -r SERVER_IP

if [[ -n "$SERVER_IP" ]]; then
    # Validation basique de l'IP
    if [[ "$SERVER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        info "Ajout de l'entrée dans /etc/hosts..."
        
        # Vérifier si l'entrée existe déjà
        if grep -q "exegol.update" /etc/hosts; then
            info "L'entrée 'exegol.update' existe déjà dans /etc/hosts"
            prompt "Voulez-vous la remplacer ? (y/N) : "
            read -r REPLACE
            if [[ "$REPLACE" =~ ^[Yy]$ ]]; then
                # Supprimer l'ancienne entrée
                sudo sed -i '/exegol.update/d' /etc/hosts
                success "Ancienne entrée supprimée"
            else
                info "Entrée conservée, aucune modification effectuée"
                exit 0
            fi
        fi
        
        # Ajouter la nouvelle entrée
        echo "$SERVER_IP exegol.update" | sudo tee -a /etc/hosts > /dev/null
        success "Entrée ajoutée : $SERVER_IP exegol.update"
        info "Vous pouvez maintenant utiliser : exu-client --server=http://exegol.update:9000"
    else
        error "Format d'adresse IP invalide. Utilisez le format : 192.168.1.100"
        exit 1
    fi
else
    info "Aucune adresse IP fournie, /etc/hosts non modifié"
fi

success "Installation terminée !"
