#!/bin/bash
# Deploy Dotfiles
# Copies dotfiles from repo to home directory with optional backup

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

REPO_ROOT="$SCRIPT_DIR/../.."
CONFIG_DIR="$REPO_ROOT/configs"

print_header "Deploy Dotfiles"

# Prompt for backup
read -p "Backup existing configs before deploying? [y/N] " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    print_info "Backup directory: $BACKUP_DIR"
    
    # Backup each config if it exists
    [ -f ~/.gitconfig ] && cp ~/.gitconfig "$BACKUP_DIR/" && print_info "Backed up .gitconfig"
    [ -f ~/.vimrc ] && cp ~/.vimrc "$BACKUP_DIR/" && print_info "Backed up .vimrc"
    [ -f ~/.config/kitty/kitty.conf ] && mkdir -p "$BACKUP_DIR/.config/kitty" && cp ~/.config/kitty/kitty.conf "$BACKUP_DIR/.config/kitty/" && print_info "Backed up kitty.conf"
    [ -f ~/.docker/config.json ] && mkdir -p "$BACKUP_DIR/.docker" && cp ~/.docker/config.json "$BACKUP_DIR/.docker/" && print_info "Backed up docker config.json"
    [ -f ~/.config/opencode/opencode.jsonc ] && mkdir -p "$BACKUP_DIR/.config/opencode" && cp ~/.config/opencode/opencode.jsonc "$BACKUP_DIR/.config/opencode/" && print_info "Backed up opencode.jsonc"
    
    print_info "Backup complete: $BACKUP_DIR"
fi

print_step "Deploying dotfiles..."

# Deploy .gitconfig
if [ -f "$CONFIG_DIR/.gitconfig" ]; then
    cp "$CONFIG_DIR/.gitconfig" ~/.gitconfig
    print_info "Deployed .gitconfig"
fi

# Deploy .vimrc
if [ -f "$CONFIG_DIR/.vim/vimrc" ]; then
    cp "$CONFIG_DIR/.vim/vimrc" ~/.vimrc
    print_info "Deployed .vimrc"
fi

# Deploy kitty.conf
if [ -f "$CONFIG_DIR/kitty.conf" ]; then
    mkdir -p ~/.config/kitty
    cp "$CONFIG_DIR/kitty.conf" ~/.config/kitty/kitty.conf
    print_info "Deployed kitty.conf"
fi

# Deploy docker config.json
if [ -f "$CONFIG_DIR/.docker/config.json" ]; then
    mkdir -p ~/.docker
    cp "$CONFIG_DIR/.docker/config.json" ~/.docker/config.json
    print_info "Deployed docker config.json"
fi

# Deploy VSCode profiles
if [ -f "$CONFIG_DIR/main_profile_linux.code-profile" ]; then
    mkdir -p ~/.config/Code/User/profiles
    cp "$CONFIG_DIR/main_profile_linux.code-profile" ~/.config/Code/User/profiles/
    print_info "Deployed VSCode profile (Linux)"
fi

if [ -f "$CONFIG_DIR/main_profile_wsl.code-profile" ]; then
    mkdir -p ~/.config/Code/User/profiles
    cp "$CONFIG_DIR/main_profile_wsl.code-profile" ~/.config/Code/User/profiles/
    print_info "Deployed VSCode profile (WSL)"
fi

# Deploy opencode config
if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
    mkdir -p ~/.config/opencode
    cp "$CONFIG_DIR/opencode.jsonc" ~/.config/opencode/opencode.jsonc
    print_info "Deployed opencode.jsonc"
fi

print_header "Dotfiles deployed successfully!"
