#!/bin/bash

# ────────────── CONFIGURATION ──────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"
CLIENT_DIR="$SCRIPT_DIR/client"

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

# ────────────── FONCTIONS UTILITAIRES ──────────────

clear_screen() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║                    EXEGOL-UPDATE SETUP                       ║${RESET}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

show_menu() {
    clear_screen
    echo -e "${YELLOW}Choisissez une option :${RESET}"
    echo
    echo -e "  ${GREEN}1${RESET} - Configuration du serveur"
    echo -e "  ${GREEN}2${RESET} - Configuration du client"
    echo -e "  ${GREEN}3${RESET} - Setup et vérification de l'environnement"
    echo -e "  ${GREEN}4${RESET} - Quitter"
    echo
    echo -e "${BLUE}Utilisez les flèches ↑↓ ou les chiffres (1-4) pour naviguer${RESET}"
    echo -e "${BLUE}Appuyez sur 'q' pour quitter directement${RESET}"
    echo
}

# ────────────── CAPTURE DES TOUCHES ──────────────

read_key() {
    local key
    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        IFS= read -rsn2 key
        if [[ $key == "[A" ]]; then
            echo "UP"
        elif [[ $key == "[B" ]]; then
            echo "DOWN"
        elif [[ $key == "[C" ]]; then
            echo "RIGHT"
        elif [[ $key == "[D" ]]; then
            echo "LEFT"
        else
            echo "UNKNOWN"
        fi
    else
        echo "$key"
    fi
}

# ────────────── VÉRIFICATION ENVIRONNEMENT ──────────────

check_environment() {
    clear_screen
    info "Setup et vérification de l'environnement..."
    echo
    
    # Vérifier Exegol
    if command -v exegol &> /dev/null; then
        success "Exegol trouvé : $(which exegol)"
    else
        error "Exegol non trouvé dans le PATH"
        return 1
    fi
    
    # Vérifier Docker
    if command -v docker &> /dev/null; then
        success "Docker trouvé : $(which docker)"
    else
        error "Docker non trouvé dans le PATH"
        return 1
    fi
    
    # Vérifier Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        success "Docker Compose disponible"
    else
        error "Docker Compose non trouvé"
        return 1
    fi
    
    # Vérifier les dossiers
    if [[ -d "$SERVER_DIR" ]]; then
        success "Dossier serveur trouvé : $SERVER_DIR"
    else
        error "Dossier serveur manquant : $SERVER_DIR"
        return 1
    fi
    
    if [[ -d "$CLIENT_DIR" ]]; then
        success "Dossier client trouvé : $CLIENT_DIR"
    else
        error "Dossier client manquant : $CLIENT_DIR"
        return 1
    fi
    
    # Créer le dossier /exu
    if [[ ! -d "/exu" ]]; then
        info "Création du dossier /exu..."
        sudo mkdir -p /exu && sudo chown -R $USER:$USER /exu
        success "Dossier /exu créé"
    else
        success "Dossier /exu existe déjà"
    fi
    
    # Créer le lien symbolique vers exegol
    EXEGOL_PATH=$(which exegol)
    
    # Vérifier si exegol est déjà directement dans /usr/local/bin/
    if [[ "$EXEGOL_PATH" == "/usr/local/bin/exegol" ]]; then
        if [[ -f "/usr/local/bin/exegol" ]]; then
            success "Exegol est déjà installé directement dans /usr/local/bin/"
        else
            error "Exegol trouvé dans /usr/local/bin/ mais le fichier n'existe pas"
            return 1
        fi
    else
        # Vérifier si le lien existe et pointe vers le bon endroit
        if [[ -L /usr/local/bin/exegol ]]; then
            CURRENT_LINK=$(readlink /usr/local/bin/exegol)
            if [[ "$CURRENT_LINK" == "$EXEGOL_PATH" ]]; then
                success "Lien symbolique vers exegol existe déjà : /usr/local/bin/exegol -> $EXEGOL_PATH"
            else
                info "Mise à jour du lien symbolique vers exegol..."
                sudo ln -sf "$EXEGOL_PATH" /usr/local/bin/exegol
                success "Lien mis à jour : /usr/local/bin/exegol -> $EXEGOL_PATH"
            fi
        else
            info "Création du lien symbolique vers exegol..."
            sudo ln -sf "$EXEGOL_PATH" /usr/local/bin/exegol
            success "Lien créé : /usr/local/bin/exegol -> $EXEGOL_PATH"
        fi
    fi
    
    # Accepter l'EULA d'Exegol
    info "Acceptation de l'EULA d'Exegol..."
    if exegol info --accept-eula &>/dev/null; then
        success "EULA d'Exegol acceptée"
    else
        info "EULA d'Exegol déjà acceptée ou non nécessaire"
    fi
    
    echo
    success "Vérification terminée !"
    echo
    prompt "Appuyez sur Entrée pour continuer..."
    read -r
}

# ────────────── CONFIGURATION SERVEUR ──────────────

setup_server() {
    clear_screen
    info "Configuration du serveur Exegol-update..."
    echo
    
    if [[ ! -f "$SERVER_DIR/setup.sh" ]]; then
        error "Script setup.sh non trouvé dans $SERVER_DIR"
        prompt "Appuyez sur Entrée pour continuer..."
        read -r
        return 1
    fi
    
    # Proposer de modifier le crontab par défaut AVANT le setup
    prompt "Voulez-vous modifier la fréquence du crontab par défaut ? (y/N) : "
    read -r cron_choice
    
    if [[ "$cron_choice" =~ ^[Yy]$ ]]; then
        modify_default_crontab
    fi
    
    prompt "Voulez-vous lancer le build immédiatement après la configuration ? (y/N) : "
    read -r NOW_BUILD
    
    if [[ "$NOW_BUILD" =~ ^[Yy]$ ]]; then
        info "Lancement de la configuration serveur avec build immédiat..."
        cd "$SERVER_DIR" && ./setup.sh --now
    else
        info "Lancement de la configuration serveur..."
        cd "$SERVER_DIR" && ./setup.sh
    fi
    
    echo
    success "Configuration serveur terminée !"
    echo
    prompt "Appuyez sur Entrée pour continuer..."
    read -r
}

# ────────────── CONFIGURATION CLIENT ──────────────

setup_client() {
    clear_screen
    info "Configuration du client Exegol-update..."
    echo
    
    if [[ ! -f "$CLIENT_DIR/initial_setup.sh" ]]; then
        error "Script initial_setup.sh non trouvé dans $CLIENT_DIR"
        prompt "Appuyez sur Entrée pour continuer..."
        read -r
        return 1
    fi
    
    info "Lancement de la configuration client..."
    cd "$CLIENT_DIR" && ./initial_setup.sh
    
    echo
    success "Configuration client terminée !"
    echo
    prompt "Appuyez sur Entrée pour continuer..."
    read -r
}

# ────────────── GESTION CRONTAB ──────────────

modify_default_crontab() {
    clear_screen
    info "Modification du crontab par défaut dans setup.sh..."
    echo
    
    # Lire la ligne actuelle du crontab dans setup.sh
    local setup_file="$SERVER_DIR/setup.sh"
    local current_cron_line=$(grep "^CRON_ENTRY=" "$setup_file" | head -1)
    
    if [[ -n "$current_cron_line" ]]; then
        info "Crontab actuel dans setup.sh :"
        echo -e "${YELLOW}$current_cron_line${RESET}"
        echo
    fi
    
    # Boucle pour relancer le choix si l'utilisateur annule
    while true; do
        # Interface visuelle pour choisir la fréquence
        select_frequency_visual
        
        # Construire la nouvelle ligne CRON_ENTRY
        local new_cron_line="CRON_ENTRY=\"$new_schedule /usr/local/bin/exu-server --force\""
        
        # Afficher la nouvelle tâche cron qui sera créée
        echo
        info "Prochaine tâche cron qui sera créée :"
        echo -e "${YELLOW}$new_schedule /usr/local/bin/exu-server --force${RESET}"
        echo
        
        # Demander confirmation
        prompt "Voulez-vous appliquer cette configuration ? (y/N) : "
        read -r confirm_cron
        
        if [[ "$confirm_cron" =~ ^[Yy]$ ]]; then
            # Modifier le fichier setup.sh
            if sed -i "s|^CRON_ENTRY=.*|$new_cron_line|" "$setup_file"; then
                success "Crontab modifié dans setup.sh :"
                echo -e "${YELLOW}$new_cron_line${RESET}"
            else
                error "Erreur lors de la modification du fichier setup.sh"
            fi
            break
        else
            info "Modification annulée, nouvelle configuration..."
            echo
            # Continuer la boucle pour relancer le choix
        fi
    done
}

select_frequency_visual() {
    echo -e "${YELLOW}Choisissez la fréquence de mise à jour :${RESET}"
    echo
    
    echo -e "  ${GREEN}1${RESET} - Mise à jour quotidienne"
    echo -e "      Tous les jours à une heure choisie"
    echo
    echo -e "  ${GREEN}2${RESET} - Mise à jour tous les X jours"
    echo -e "      Tous les X jours à une heure choisie"
    echo
    echo -e "  ${GREEN}3${RESET} - Configuration personnalisée"
    echo -e "      Choisir le jour et l'heure"
    echo
    
    prompt "Votre choix (1-3) : "
    read -r frequency_choice
    
    case $frequency_choice in
        1)
            select_daily_frequency
            ;;
        2)
            select_interval_frequency
            ;;
        3)
            select_custom_frequency
            ;;
        *)
            error "Choix invalide, utilisation de la fréquence par défaut"
            new_schedule="0 20 * * *"
            ;;
    esac
}

select_daily_frequency() {
    echo
    info "Configuration de la mise à jour quotidienne"
    echo
    
    prompt "Entrez l'heure de mise à jour (0-23) : "
    read -r hour_choice
    
    # Validation de l'heure
    if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
        new_schedule="0 $hour_choice * * *"
        
        echo
        info "Résumé de votre configuration :"
        echo -e "${YELLOW}   Mise à jour tous les jours à ${hour_choice}h00${RESET}"
    else
        error "Heure invalide, utilisation de 20h00"
        new_schedule="0 20 * * *"
        
        echo
        info "Résumé de votre configuration :"
        echo -e "${YELLOW}   Mise à jour tous les jours à 20h00${RESET}"
    fi
}

select_interval_frequency() {
    echo
    info "Configuration de la mise à jour tous les X jours"
    echo
    
    prompt "Entrez le nombre de jours entre chaque mise à jour (1-31) : "
    read -r day_interval
    
    # Validation de l'intervalle
    if [[ "$day_interval" =~ ^[1-9]$ ]] || [[ "$day_interval" =~ ^1[0-9]$ ]] || [[ "$day_interval" =~ ^2[0-9]$ ]] || [[ "$day_interval" =~ ^3[0-1]$ ]]; then
        echo
        prompt "Entrez l'heure de mise à jour (0-23) : "
        read -r hour_choice
        
        # Validation de l'heure
        if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
            new_schedule="0 $hour_choice */$day_interval * *"
            
            echo
            info "Résumé de votre configuration :"
            echo -e "${YELLOW}   Mise à jour tous les ${day_interval} jours à ${hour_choice}h00${RESET}"
        else
            error "Heure invalide, utilisation de 20h00"
            new_schedule="0 20 */$day_interval * *"
            
            echo
            info "Résumé de votre configuration :"
            echo -e "${YELLOW}   Mise à jour tous les ${day_interval} jours à 20h00${RESET}"
        fi
    else
        error "Intervalle invalide, utilisation de 1 jour"
        new_schedule="0 20 * * *"
        
        echo
        info "Résumé de votre configuration :"
        echo -e "${YELLOW}   Mise à jour tous les jours à 20h00${RESET}"
    fi
}

select_custom_frequency() {
    echo
    info "⚙️ Configuration personnalisée"
    echo
    
    # Sélection du jour
    echo -e "${YELLOW}📅 Choisissez le jour :${RESET}"
    echo -e "  ${GREEN}1${RESET} - Lundi"
    echo -e "  ${GREEN}2${RESET} - Mardi"
    echo -e "  ${GREEN}3${RESET} - Mercredi"
    echo -e "  ${GREEN}4${RESET} - Jeudi"
    echo -e "  ${GREEN}5${RESET} - Vendredi"
    echo -e "  ${GREEN}6${RESET} - Samedi"
    echo -e "  ${GREEN}7${RESET} - Dimanche"
    echo -e "  ${GREEN}8${RESET} - Tous les jours"
    echo
    
    prompt "Jour (1-8) : "
    read -r day_choice
    
    local day_schedule=""
    local day_names=("" "Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi" "Dimanche")
    case $day_choice in
        1) day_schedule="* * 1" ;;
        2) day_schedule="* * 2" ;;
        3) day_schedule="* * 3" ;;
        4) day_schedule="* * 4" ;;
        5) day_schedule="* * 5" ;;
        6) day_schedule="* * 6" ;;
        7) day_schedule="* * 0" ;;
        8) day_schedule="* * *" ;;
        *) 
            error "Choix invalide, utilisation du samedi"
            day_schedule="* * 6"
            day_choice=6
            ;;
    esac
    
    # Sélection de l'heure
    echo
    prompt "Entrez l'heure de mise à jour (0-23) : "
    read -r hour_choice
    
    # Validation de l'heure
    if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
        local hour_schedule="0 $hour_choice"
        new_schedule="$hour_schedule $day_schedule"
        
        # Afficher un résumé
        echo
        info "📋 Résumé de votre configuration :"
        if [[ "$day_choice" == "8" ]]; then
            echo -e "${YELLOW}   Mise à jour tous les jours à ${hour_choice}h00${RESET}"
        else
            echo -e "${YELLOW}   Mise à jour tous les ${day_names[$day_choice]}s à ${hour_choice}h00${RESET}"
        fi
    else
        error "Heure invalide, utilisation de 20h00"
        new_schedule="0 20 $day_schedule"
        
        echo
        info "📋 Résumé de votre configuration :"
        if [[ "$day_choice" == "8" ]]; then
            echo -e "${YELLOW}   Mise à jour tous les jours à 20h00${RESET}"
        else
            echo -e "${YELLOW}   Mise à jour tous les ${day_names[$day_choice]}s à 20h00${RESET}"
        fi
    fi
}

validate_cron_format() {
    local cron_expr="$1"
    
    # Vérifier que l'expression a exactement 5 champs
    local field_count=$(echo "$cron_expr" | wc -w)
    if [[ $field_count -ne 5 ]]; then
        return 1
    fi
    
    # Extraire les champs
    local minute=$(echo "$cron_expr" | awk '{print $1}')
    local hour=$(echo "$cron_expr" | awk '{print $2}')
    local day_month=$(echo "$cron_expr" | awk '{print $3}')
    local month=$(echo "$cron_expr" | awk '{print $4}')
    local day_week=$(echo "$cron_expr" | awk '{print $5}')
    
    # Validation basique des champs
    # Minute: 0-59
    if ! [[ "$minute" =~ ^[0-5]?[0-9]$ ]] && [[ "$minute" != "*" ]]; then
        return 1
    fi
    
    # Heure: 0-23
    if ! [[ "$hour" =~ ^[0-2]?[0-9]$ ]] && [[ "$hour" != "*" ]]; then
        return 1
    fi
    
    # Jour du mois: 1-31
    if ! [[ "$day_month" =~ ^[1-3]?[0-9]$ ]] && [[ "$day_month" != "*" ]]; then
        return 1
    fi
    
    # Mois: 1-12
    if ! [[ "$month" =~ ^[1-9]?[0-2]?$ ]] && [[ "$month" != "*" ]]; then
        return 1
    fi
    
    # Jour de la semaine: 0-7 (0 et 7 = dimanche)
    if ! [[ "$day_week" =~ ^[0-7]$ ]] && [[ "$day_week" != "*" ]]; then
        return 1
    fi
    
    return 0
}



# ────────────── MENU PRINCIPAL ──────────────

main_menu() {
    local current_choice=1
    local max_choices=4
    
    while true; do
        show_menu
        
        # Afficher le curseur sur l'option actuelle
        case $current_choice in
            1) echo -e "  ${GREEN}▶ 1${RESET} - Configuration du serveur" ;;
            2) echo -e "  ${GREEN}▶ 2${RESET} - Configuration du client" ;;
            3) echo -e "  ${GREEN}▶ 3${RESET} - Setup et vérification de l'environnement" ;;
            4) echo -e "  ${GREEN}▶ 4${RESET} - Quitter" ;;
        esac
        
        echo
        prompt "Appuyez sur Entrée pour sélectionner : "
        
        # Capturer la touche
        local key=$(read_key)
        
        case $key in
            "UP")
                if [[ $current_choice -gt 1 ]]; then
                    ((current_choice--))
                else
                    current_choice=$max_choices
                fi
                ;;
            "DOWN")
                if [[ $current_choice -lt $max_choices ]]; then
                    ((current_choice++))
                else
                    current_choice=1
                fi
                ;;
            "1"|"2"|"3"|"4")
                current_choice=$key
                ;;
            "q"|"Q")
                clear_screen
                info "Au revoir !"
                exit 0
                ;;
            "")  # Entrée
                case $current_choice in
                    1)
                        setup_server
                        ;;
                    2)
                        setup_client
                        ;;
                    3)
                        check_environment
                        ;;
                    4)
                        clear_screen
                        info "Au revoir !"
                        exit 0
                        ;;
                esac
                ;;
            *)
                # Ignorer les autres touches
                ;;
        esac
    done
}

# ────────────── POINT D'ENTRÉE ──────────────

main_menu
