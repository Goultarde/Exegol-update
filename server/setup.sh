
#!/bin/bash

set -e

# ───────────── CONFIG ─────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEGOL_SCRIPT="$SCRIPT_DIR/exu-server"
CRON_TMP="/tmp/crontab_check.txt"
CONTAINER_NAME="exegol-nginx"
CRON_ENTRY="* 2 * * * $EXEGOL_SCRIPT"
#* * * * * commande
#| | | | |
#| | | | └── Jour de la semaine (0-7) (0 ou 7 = dimanche)
#| | | └──── Mois (1-12)
#| | └────── Jour du mois (1-31)
#| └──────── Heure (0-23)
#└────────── Minute (0-59)

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

# ───────────── Préparation des dossiers ─────────────

info "Création des répertoires si besoin..."
mkdir -p /exu/exegol-update-server/exegol-tars
mkdir -p /var/log

# ───────────── Nettoyage Docker précédent ─────────────

if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
    info "Conteneur $CONTAINER_NAME détecté. Suppression en cours..."
    docker rm -f "$CONTAINER_NAME" && success "Conteneur supprimé : $CONTAINER_NAME"
fi

# ───────────── Lancer Docker Compose ─────────────

info "Construction et lancement de Nginx avec Docker Compose..."
docker compose -f "$SCRIPT_DIR/docker/docker-compose.yml" up -d --build

# ───────────── Ajout crontab si absente ─────────────

info "Vérification de la présence de la tâche cron pour exu-server..."

crontab -l 2>/dev/null > "$CRON_TMP" || touch "$CRON_TMP"

if grep -Fq "$EXEGOL_SCRIPT" "$CRON_TMP"; then
    info "Tâche cron déjà présente, rien à faire."
else
    echo "$CRON_ENTRY" >> "$CRON_TMP"
    crontab "$CRON_TMP"
    success "Tâche cron ajoutée : $CRON_ENTRY"
fi

rm -f "$CRON_TMP"

success "✅ Setup terminé. Serveur Nginx en ligne et exu-server automatisé."

