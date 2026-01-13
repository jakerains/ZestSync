#!/bin/bash
# ZestSync - Menu UI Library

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m'

# Box drawing
draw_header() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║              🍋 ZestSync                       ║"
    echo "  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
}

draw_box_top() {
    local width=${1:-45}
    printf "  ╭"
    printf '─%.0s' $(seq 1 $width)
    printf "╮\n"
}

draw_box_bottom() {
    local width=${1:-45}
    printf "  ╰"
    printf '─%.0s' $(seq 1 $width)
    printf "╯\n"
}

draw_separator() {
    local width=${1:-45}
    printf "  ├"
    printf '─%.0s' $(seq 1 $width)
    printf "┤\n"
}

# Prompts
prompt() {
    local message="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        echo -ne "  ${CYAN}$message${NC} ${DIM}[$default]${NC}: "
        read result
        echo "${result:-$default}"
    else
        echo -ne "  ${CYAN}$message${NC}: "
        read result
        echo "$result"
    fi
}

prompt_path() {
    local message="$1"
    local default="$2"
    local result
    
    echo -ne "  ${CYAN}$message${NC}"
    [[ -n "$default" ]] && echo -ne " ${DIM}[$default]${NC}"
    echo -ne ": "
    
    # Read with tab completion
    read -e result
    result="${result:-$default}"
    
    # Expand ~ to home
    result="${result/#\~/$HOME}"
    echo "$result"
}

confirm() {
    local message="$1"
    local default="${2:-n}"
    local result
    
    if [[ "$default" == "y" ]]; then
        echo -ne "  ${YELLOW}$message${NC} ${DIM}[Y/n]${NC}: "
    else
        echo -ne "  ${YELLOW}$message${NC} ${DIM}[y/N]${NC}: "
    fi
    
    read result
    result="${result:-$default}"
    
    [[ "$result" =~ ^[Yy] ]]
}

select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local key
    
    # Hide cursor
    tput civis
    
    while true; do
        # Draw options
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "  ${GREEN}▸ ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        # Read single key
        read -rsn1 key
        
        # Handle arrow keys
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') ((selected > 0)) && ((selected--)) ;;  # Up
                '[B') ((selected < ${#options[@]}-1)) && ((selected++)) ;;  # Down
            esac
        elif [[ $key == "" ]]; then
            break
        fi
        
        # Move cursor up to redraw
        tput cuu ${#options[@]}
    done
    
    # Show cursor
    tput cnorm
    
    echo $selected
}

show_success() {
    echo -e "\n  ${GREEN}✓ $1${NC}\n"
}

show_error() {
    echo -e "\n  ${RED}✗ $1${NC}\n"
}

show_info() {
    echo -e "  ${DIM}$1${NC}"
}

press_enter() {
    echo -ne "\n  ${DIM}Press Enter to continue...${NC}"
    read
}

spinner() {
    local pid=$1
    local message="${2:-Working...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    tput civis
    while kill -0 $pid 2>/dev/null; do
        printf "\r  ${CYAN}${spin:$i:1}${NC} $message"
        ((i = (i + 1) % 10))
        sleep 0.1
    done
    tput cnorm
    printf "\r"
}
