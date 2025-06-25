#!/bin/bash

# ───────────── CONFIGURATION ─────────────

SERVER_URL="http://localhost:9000/"
DEST_DIR="/opt/exegol-update-client"

# ───────────── COULEURS ─────────────

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }
prompt()  { echo -ne "${YELLOW}[?]${RESET} $1"; }

# ───────────── LOGIQUE ─────────────

mkdir -p "$DEST_DIR"

info "Récupération de la liste des fichiers .tar sur le serveur..."
FILE_LIST=$(curl -s "$SERVER_URL/" | grep -oP 'href="[^"]+\.tar"' | cut -d'"' -f2)

if [ -z "$FILE_LIST" ]; then
    error "Aucun fichier .tar trouvé sur le serveur."
    exit 1
fi

LATEST_TAR=$(echo "$FILE_LIST" | sort -r | head -n 1)
TAR_NAME=$(basename "$LATEST_TAR")
TAR_URL="$SERVER_URL/$TAR_NAME"
LOCAL_PATH="$DEST_DIR/$TAR_NAME"

info "Dernier fichier disponible : $TAR_NAME"

if [ -f "$LOCAL_PATH" ]; then
    info "Le fichier $TAR_NAME est déjà présent localement."
    info "Aucun chargement Docker ne sera effectué."
    exit 0
else
    prompt "Voulez-vous télécharger ce fichier ? (y/N) : "
    read -r CONFIRM_DL
    if [[ "$CONFIRM_DL" =~ ^[Yy]$ ]]; then
        info "Téléchargement de $TAR_NAME..."
        curl -fSL "$TAR_URL" -o "$LOCAL_PATH" || {
            error "Échec du téléchargement."
            exit 1
        }
        success "Téléchargement terminé."

        info "Chargement de l’image Docker depuis $TAR_NAME..."
        docker load -i "$LOCAL_PATH" || {
            error "Échec du chargement de l’image."
            exit 1
        }
        success "Image Docker chargée avec succès."

        prompt "Voulez-vous supprimer le fichier $TAR_NAME après chargement ? (y/n) : "
        read -r CONFIRM_DELETE
        if [[ "$CONFIRM_DELETE" =~ ^[Yy]$ ]]; then
            rm -f "$LOCAL_PATH"
            success "Fichier supprimé."
        else
            info "Fichier conservé dans $DEST_DIR/"
        fi
    else
        info "Téléchargement annulé par l'utilisateur."
        exit 0
    fi
fi

