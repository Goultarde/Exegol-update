#!/bin/bash

# ────────────── CONFIGURATION ──────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"
CLIENT_DIR="$SCRIPT_DIR/client"

# ────────────── COLORS ──────────────

BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }
prompt()  { echo -ne "${YELLOW}[?]${RESET} $1"; }

# ────────────── UTILITY FUNCTIONS ──────────────

clear_screen() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║                    EXEGOL-UPDATE SETUP                       ║${RESET}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

show_menu() {
    clear_screen
    echo -e "${YELLOW}Choose an option:${RESET}"
    echo
    echo -e "  ${GREEN}1${RESET} - Setup and check environment"
    echo -e "  ${GREEN}2${RESET} - Server configuration"
    echo -e "  ${GREEN}3${RESET} - Client configuration"
    echo -e "  ${GREEN}4${RESET} - Build locally (Docker build only)"
    echo -e "  ${GREEN}5${RESET} - Uninstall server configuration"
    echo -e "  ${GREEN}6${RESET} - Exit"
    echo
    echo -e "${BLUE}Use ↑↓ arrows or numbers (1-6) to navigate${RESET}"
    echo -e "${BLUE}Press 'q' to quit directly${RESET}"
    echo
}

# ────────────── KEY COMMAND CAPTURE ──────────────

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

# ────────────── ENVIRONMENT CHECK ──────────────

check_environment() {
    clear_screen
    info "Setting up and checking environment..."
    echo
    
    local errors_found=0
    
    # Check Exegol
    if command -v exegol &> /dev/null; then
        success "Exegol found: $(which exegol)"
    else
        error "Exegol not found in PATH"
        ((errors_found++))
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        success "Docker found: $(which docker)"
    else
        error "Docker not found in PATH"
        ((errors_found++))
    fi
    
    # Check Docker Compose
    local docker_compose_available=false
    local docker_compose_version=""
    
    if command -v docker-compose &> /dev/null; then
        docker_compose_version=$(docker-compose --version 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            success "Docker Compose v1 found: $docker_compose_version"
            docker_compose_available=true
        fi
    fi
    
    if [[ "$docker_compose_available" == "false" ]] && command -v docker &> /dev/null; then
        docker_compose_version=$(docker compose version 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            success "Docker Compose v2 found: $docker_compose_version"
            docker_compose_available=true
        fi
    fi
    
    if [[ "$docker_compose_available" == "false" ]]; then
        error "Docker Compose not found or not working"
        error "Please ensure that docker-compose (v1) or 'docker compose' (v2) is installed and functional"
        ((errors_found++))
    fi
    
    # Check directories
    if [[ -d "$SERVER_DIR" ]]; then
        success "Server directory found: $SERVER_DIR"
    else
        error "Missing server directory: $SERVER_DIR"
        ((errors_found++))
    fi
    
    if [[ -d "$CLIENT_DIR" ]]; then
        success "Client directory found: $CLIENT_DIR"
    else
        error "Missing client directory: $CLIENT_DIR"
        ((errors_found++))
    fi
    
    # Create /exu directory
    if [[ ! -d "/exu" ]]; then
        info "Creating /exu directory..."
        sudo mkdir -p /exu && sudo chown -R $USER:$USER /exu
        success "Directory /exu created"
    else
        success "Directory /exu already exists"
    fi
    
    # Create symlink to exegol
    EXEGOL_PATH=$(which exegol)
    
    # Check if exegol is already in /usr/local/bin/
    if [[ "$EXEGOL_PATH" == "/usr/local/bin/exegol" ]]; then
        if [[ -f "/usr/local/bin/exegol" ]]; then
            success "Exegol is already installed directly in /usr/local/bin/"
        else
            error "Exegol found in /usr/local/bin/ but the file does not exist"
            return 1
        fi
    else
        # Check if the symlink exists and points to the correct location
        if [[ -L /usr/local/bin/exegol ]]; then
            CURRENT_LINK=$(readlink /usr/local/bin/exegol)
            if [[ "$CURRENT_LINK" == "$EXEGOL_PATH" ]]; then
                success "Symlink to exegol already exists: /usr/local/bin/exegol -> $EXEGOL_PATH"
            else
                info "Updating symlink to exegol..."
                sudo ln -sf "$EXEGOL_PATH" /usr/local/bin/exegol
                success "Symlink updated: /usr/local/bin/exegol -> $EXEGOL_PATH"
            fi
        else
            info "Creating symlink to exegol..."
            sudo ln -sf "$EXEGOL_PATH" /usr/local/bin/exegol
            success "Symlink created: /usr/local/bin/exegol -> $EXEGOL_PATH"
        fi
    fi
    
    # Accept Exegol EULA
    info "Accepting Exegol EULA..."
    if exegol info --accept-eula &>/dev/null; then
        success "Exegol EULA accepted"
    else
        info "Exegol EULA already accepted or not required"
    fi
    
    echo
    if [[ $errors_found -eq 0 ]]; then
        success "Check completed successfully!"
    else
        error "Check completed with $errors_found error(s)"
        echo
        info "Summary of detected issues:"
        echo "  - Verify that all required tools are installed"
        echo "  - Verify that you have sudo rights if needed"
        echo "  - Verify that project directories exist"
    fi
    echo
    prompt "Press Enter to continue..."
    read -r
}

# ────────────── SERVER CONFIGURATION ──────────────

setup_server() {
    clear_screen
    info "Setting up Exegol-update server..."
    echo
    
    if [[ ! -f "$SERVER_DIR/setup.sh" ]]; then
        error "setup.sh script not found in $SERVER_DIR"
        prompt "Press Enter to continue..."
        read -r
        return 1
    fi
    
    # Offer to change default crontab BEFORE setup
    prompt "Do you want to change the default crontab frequency? (y/N): "
    read -r cron_choice
    
    if [[ "$cron_choice" =~ ^[Yy]$ ]]; then
        modify_default_crontab
    fi
    
    prompt "Do you want to change the default image repository (Repo)? (y/N): "
    read -r change_repo
    local custom_repo=""
    if [[ "$change_repo" =~ ^[Yy]$ ]]; then
        prompt "Enter repository URL: "
        read -r custom_repo
    fi

    prompt "Do you want to change the image build profile (e.g., full(default), light, ad, web, custom)? (y/N): "
    read -r change_profile
    local custom_profile=""
    if [[ "$change_profile" =~ ^[Yy]$ ]]; then
        prompt "Enter profile name: "
        read -r custom_profile
    fi

    local setup_flags=()
    if [[ -n "$custom_repo" ]]; then
        setup_flags+=(--repo "$custom_repo")
    fi
    if [[ -n "$custom_profile" ]]; then
        setup_flags+=(--profile "$custom_profile")
    fi
    
    prompt "Do you want to run the build immediately after setup? (y/N): "
    read -r NOW_BUILD
    
    if [[ "$NOW_BUILD" =~ ^[Yy]$ ]]; then
        setup_flags+=(--now)
        info "Running server configuration with immediate build..."
    else
        info "Running server configuration..."
    fi
    
    cd "$SERVER_DIR" && ./setup.sh "${setup_flags[@]}"
    
    echo
    success "Server configuration complete!"
    echo
    prompt "Press Enter to continue..."
    read -r
}

# ────────────── SERVER UNINSTALLATION ──────────────

uninstall_server() {
    clear_screen
    info "Uninstalling Exegol-update server configuration..."
    echo
    
    prompt "Do you really want to remove EVERYTHING (Docker, Crontab, Binary)? (y/N): "
    read -r confirm_del
    
    if [[ "$confirm_del" =~ ^[Yy]$ ]]; then
        cd "$SERVER_DIR" && ./setup.sh --uninstall
    else
        info "Uninstallation cancelled."
    fi
    
    echo
    prompt "Press Enter to return to menu..."
    read -r
}


# ────────────── CLIENT CONFIGURATION ──────────────

setup_client() {
    clear_screen
    info "Setting up Exegol-update client..."
    echo
    
    if [[ ! -f "$CLIENT_DIR/initial_setup.sh" ]]; then
        error "initial_setup.sh script not found in $CLIENT_DIR"
        prompt "Press Enter to continue..."
        read -r
        return 1
    fi
    
    info "Running client configuration..."
    cd "$CLIENT_DIR" && ./initial_setup.sh
    
    echo
    success "Client configuration complete!"
    echo
    prompt "Press Enter to continue..."
    read -r
}

# ────────────── CRONTAB MANAGEMENT ──────────────

modify_default_crontab() {
    clear_screen
    info "Modifying default crontab in setup.sh..."
    echo
    
    # Read current crontab line in setup.sh
    local setup_file="$SERVER_DIR/setup.sh"
    local current_cron_line=$(grep "^CRON_ENTRY=" "$setup_file" | head -1)
    
    if [[ -n "$current_cron_line" ]]; then
        info "Current crontab in setup.sh:"
        echo -e "${YELLOW}$current_cron_line${RESET}"
        echo
    fi
    
    # Loop to restart choice if user cancels
    while true; do
        # Visual interface for frequency selection
        select_frequency_visual
        
        # Build new CRON_ENTRY line
        local new_cron_line="CRON_ENTRY=\"$new_schedule /usr/local/bin/exu-server --force\""
        
        # Display new cron task that will be created
        echo
        info "Next cron task to be created:"
        echo -e "${YELLOW}$new_cron_line${RESET}"
        echo
        
        # Ask for confirmation
        prompt "Do you want to apply this configuration? (y/N): "
        read -r confirm_cron
        
        if [[ "$confirm_cron" =~ ^[Yy]$ ]]; then
            # Modify setup.sh file
            if sed -i "s|^CRON_ENTRY=.*|$new_cron_line|" "$setup_file"; then
                success "Crontab modified in setup.sh:"
                echo -e "${YELLOW}$new_cron_line${RESET}"
            else
                error "Error modifying setup.sh file"
            fi
            break
        else
            info "Modification cancelled, starting new configuration..."
            echo
            # Continue loop to restart choice
        fi
    done
}

select_frequency_visual() {
    echo -e "${YELLOW}Choose update frequency:${RESET}"
    echo
    
    echo -e "  ${GREEN}1${RESET} - Daily update"
    echo -e "      Every day at a chosen time"
    echo
    echo -e "  ${GREEN}2${RESET} - Update every X days"
    echo -e "      Every X days at a chosen time"
    echo
    echo -e "  ${GREEN}3${RESET} - Custom configuration"
    echo -e "      Choose day and time"
    echo
    
    prompt "Your choice (1-3): "
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
            error "Invalid choice, using default frequency"
            new_schedule="0 20 * * *"
            ;;
    esac
}

select_daily_frequency() {
    echo
    info "Setting up daily update"
    echo
    
    prompt "Enter update hour (0-23): "
    read -r hour_choice
    
    # Hour validation
    if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
        new_schedule="0 $hour_choice * * *"
        
        echo
        info "Configuration summary:"
        echo -e "${YELLOW}   Update every day at ${hour_choice}:00${RESET}"
    else
        error "Invalid hour, using 20:00"
        new_schedule="0 20 * * *"
        
        echo
        info "Configuration summary:"
        echo -e "${YELLOW}   Update every day at 20:00${RESET}"
    fi
}

select_interval_frequency() {
    echo
    info "Setting up X days interval update"
    echo
    
    prompt "Enter the number of days between each update (1-31): "
    read -r day_interval
    
    # Interval validation
    if [[ "$day_interval" =~ ^[1-9]$ ]] || [[ "$day_interval" =~ ^1[0-9]$ ]] || [[ "$day_interval" =~ ^2[0-9]$ ]] || [[ "$day_interval" =~ ^3[0-1]$ ]]; then
        echo
        prompt "Enter update hour (0-23): "
        read -r hour_choice
        
        # Hour validation
        if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
            new_schedule="0 $hour_choice */$day_interval * *"
            
            echo
            info "Configuration summary:"
            echo -e "${YELLOW}   Update every ${day_interval} days at ${hour_choice}:00${RESET}"
        else
            error "Invalid hour, using 20:00"
            new_schedule="0 20 */$day_interval * *"
            
            echo
            info "Configuration summary:"
            echo -e "${YELLOW}   Update every ${day_interval} days at 20:00${RESET}"
        fi
    else
        error "Invalid interval, using 1 day"
        new_schedule="0 20 * * *"
        
        echo
        info "Configuration summary:"
        echo -e "${YELLOW}   Update every day at 20:00${RESET}"
    fi
}

select_custom_frequency() {
    echo
    info "Custom configuration"
    echo
    
    # Day selection
    echo -e "${YELLOW}Choose the day:${RESET}"
    echo -e "  ${GREEN}1${RESET} - Monday"
    echo -e "  ${GREEN}2${RESET} - Tuesday"
    echo -e "  ${GREEN}3${RESET} - Wednesday"
    echo -e "  ${GREEN}4${RESET} - Thursday"
    echo -e "  ${GREEN}5${RESET} - Friday"
    echo -e "  ${GREEN}6${RESET} - Saturday"
    echo -e "  ${GREEN}7${RESET} - Sunday"
    echo -e "  ${GREEN}8${RESET} - Every day"
    echo
    
    prompt "Day (1-8): "
    read -r day_choice
    
    local day_schedule=""
    local day_names=("" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
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
            error "Invalid choice, using Saturday"
            day_schedule="* * 6"
            day_choice=6
            ;;
    esac
    
    # Hour selection
    echo
    prompt "Enter update hour (0-23): "
    read -r hour_choice
    
    # Hour validation
    if [[ "$hour_choice" =~ ^[0-9]$ ]] || [[ "$hour_choice" =~ ^1[0-9]$ ]] || [[ "$hour_choice" =~ ^2[0-3]$ ]]; then
        local hour_schedule="0 $hour_choice"
        new_schedule="$hour_schedule $day_schedule"
        
        # Display summary
        echo
        info "Configuration summary:"
        if [[ "$day_choice" == "8" ]]; then
            echo -e "${YELLOW}   Update every day at ${hour_choice}:00${RESET}"
        else
            echo -e "${YELLOW}   Update every ${day_names[$day_choice]} at ${hour_choice}:00${RESET}"
        fi
    else
        error "Invalid hour, using 20:00"
        new_schedule="0 20 $day_schedule"
        
        echo
        info "Configuration summary:"
        if [[ "$day_choice" == "8" ]]; then
            echo -e "${YELLOW}   Update every day at 20:00${RESET}"
        else
            echo -e "${YELLOW}   Update every ${day_names[$day_choice]} at 20:00${RESET}"
        fi
    fi
}

validate_cron_format() {
    local cron_expr="$1"
    
    # Verify that the expression has exactly 5 fields
    local field_count=$(echo "$cron_expr" | wc -w)
    if [[ $field_count -ne 5 ]]; then
        return 1
    fi
    
    # Extract fields
    local minute=$(echo "$cron_expr" | awk '{print $1}')
    local hour=$(echo "$cron_expr" | awk '{print $2}')
    local day_month=$(echo "$cron_expr" | awk '{print $3}')
    local month=$(echo "$cron_expr" | awk '{print $4}')
    local day_week=$(echo "$cron_expr" | awk '{print $5}')
    
    # Basic field validation
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
    
    # Month: 1-12
    if ! [[ "$month" =~ ^[1-9]?[0-2]?$ ]] && [[ "$month" != "*" ]]; then
        return 1
    fi
    
    # Day of week: 0-7 (0 and 7 = Sunday)
    if ! [[ "$day_week" =~ ^[0-7]$ ]] && [[ "$day_week" != "*" ]]; then
        return 1
    fi
    
    return 0
}



# ────────────── MAIN MENU ──────────────

main_menu() {
    local current_choice=1
    local max_choices=6
    
    while true; do
        show_menu
        
        # Display cursor on current option
        case $current_choice in
            1) echo -e "  ${GREEN}▶ 1${RESET} - Setup and check environment" ;;
            2) echo -e "  ${GREEN}▶ 2${RESET} - Server configuration" ;;
            3) echo -e "  ${GREEN}▶ 3${RESET} - Client configuration" ;;
            4) echo -e "  ${GREEN}▶ 4${RESET} - Build locally (Docker build only)" ;;
            5) echo -e "  ${GREEN}▶ 5${RESET} - Uninstall server configuration" ;;
            6) echo -e "  ${GREEN}▶ 6${RESET} - Exit" ;;
        esac
        
        echo
        prompt "Press Enter to select: "
        
        # Capture key
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
            "1"|"2"|"3"|"4"|"5"|"6")
                current_choice=$key
                ;;
            "q"|"Q")
                clear_screen
                info "Goodbye!"
                exit 0
                ;;
            "")  # Enter
                case $current_choice in
                    1)
                        check_environment
                        ;;
                    2)
                        setup_server
                        ;;
                    3)
                        setup_client
                        ;;
                    4)
                        build_local_only
                        ;;
                    5)
                        uninstall_server
                        ;;
                    6)
                        clear_screen
                        info "Goodbye!"
                        exit 0
                        ;;
                esac
                ;;
            *)
                # Ignore other keys
                ;;
        esac
    done
}

# ────────────── LOCAL BUILD ──────────────

build_local_only() {
    clear_screen
    info "Local Exegol build (Docker build only, no tar export)"
    echo
    
    # Check that script exists
    if [[ ! -f "$SERVER_DIR/exu-server" ]]; then
        error "exu-server script not found in $SERVER_DIR"
        prompt "Press Enter to continue..."
        read -r
        return 1
    fi
    
    # Ensure necessary directories exist
    info "Preparing directories..."
    sudo mkdir -p /exu/exegol-update-server/exu-tars
    sudo mkdir -p /exu/exegol-update-server/exu-logs
    sudo chown -R $USER:$USER /exu/exegol-update-server
    sudo chmod 755 /exu/exegol-update-server/exu-tars
    sudo chmod 755 /exu/exegol-update-server/exu-logs
    
    # Ask whether to force build (default yes)
    prompt "Force build even if no new commit? (Y/n): "
    read -r force_build
    local force_flag="--force"
    if [[ "$force_build" =~ ^[Nn]$ ]]; then
        force_flag=""
    fi
    
    # Ask for final image name
    echo
    prompt "Final image name (e.g., myexegol:latest or leave empty for default): "
    read -r custom_image_name
    
    # Run build
    cd "$SERVER_DIR" && ./exu-server --build-only $force_flag
    
    # If custom name provided, retag image
    if [[ -n "$custom_image_name" ]]; then
        echo
        info "Retagging image with custom name..."
        
        # Build full name if needed
        if [[ "$custom_image_name" != */* && "$custom_image_name" != *:* ]]; then
            custom_image_name="nwodtuhs/exegol:${custom_image_name}"
        fi
        
        # Find built image (usually serverfull or serverlight)
        local built_image=""
        if docker images | grep -q "nwodtuhs/exegol:serverfull"; then
            built_image="nwodtuhs/exegol:serverfull"
        elif docker images | grep -q "nwodtuhs/exegol:serverlight"; then
            built_image="nwodtuhs/exegol:serverlight"
        fi
        
        if [[ -n "$built_image" ]]; then
            # Check if destination image already exists
            if docker image inspect "$custom_image_name" &>/dev/null; then
                prompt "Image $custom_image_name already exists. Replace it? (y/N): "
                read -r replace_image
                if [[ "$replace_image" =~ ^[Yy]$ ]]; then
                    docker image rm "$custom_image_name" &>/dev/null
                    success "Old image removed: $custom_image_name"
                else
                    info "Retag cancelled."
                    custom_image_name=""
                fi
            fi
            
            if [[ -n "$custom_image_name" ]]; then
                docker tag "$built_image" "$custom_image_name"
                success "Image retagged: $custom_image_name"
            fi
        else
            error "Could not find built image to retag"
        fi
    fi
    
    echo
    success "Local build complete!"
    prompt "Press Enter to continue..."
    read -r
}

# ────────────── ENTRY POINT ──────────────

main_menu
