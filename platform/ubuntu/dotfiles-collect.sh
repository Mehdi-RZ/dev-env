#!/bin/bash
# Collect Dotfiles
# Copies dotfiles from home directory back to repo

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

REPO_ROOT="$SCRIPT_DIR/../.."
CONFIG_DIR="$REPO_ROOT/configs"

print_header "Collect Dotfiles"

print_step "Collecting dotfiles from home directory..."

# Collect .gitconfig
if [ -f ~/.gitconfig ]; then
    cp ~/.gitconfig "$CONFIG_DIR/.gitconfig"
    print_info "Collected .gitconfig"
else
    print_warn ".gitconfig not found in home directory"
fi

# Collect .vimrc
if [ -f ~/.vimrc ]; then
    mkdir -p "$CONFIG_DIR/.vim"
    cp ~/.vimrc "$CONFIG_DIR/.vim/vimrc"
    print_info "Collected .vimrc"
else
    print_warn ".vimrc not found in home directory"
fi

# Collect kitty.conf
if [ -f ~/.config/kitty/kitty.conf ]; then
    cp ~/.config/kitty/kitty.conf "$CONFIG_DIR/kitty.conf"
    print_info "Collected kitty.conf"
else
    print_warn "kitty.conf not found"
fi

# Collect docker config.json
if [ -f ~/.docker/config.json ]; then
    mkdir -p "$CONFIG_DIR/.docker"
    cp ~/.docker/config.json "$CONFIG_DIR/.docker/config.json"
    print_info "Collected docker config.json"
else
    print_warn "docker config.json not found"
fi

# Collect VSCode profiles
if [ -f ~/.config/Code/User/profiles/main_profile_linux.code-profile ]; then
    cp ~/.config/Code/User/profiles/main_profile_linux.code-profile "$CONFIG_DIR/"
    print_info "Collected VSCode profile (Linux)"
fi

if [ -f ~/.config/Code/User/profiles/main_profile_wsl.code-profile ]; then
    cp ~/.config/Code/User/profiles/main_profile_wsl.code-profile "$CONFIG_DIR/"
    print_info "Collected VSCode profile (WSL)"
fi

# Collect opencode config
if [ -f ~/.config/opencode/opencode.jsonc ]; then
    mkdir -p "$CONFIG_DIR/agents-env/opencode"
    cp ~/.config/opencode/opencode.jsonc "$CONFIG_DIR/agents-env/opencode/opencode.jsonc"
    print_info "Collected opencode.jsonc"
else
    print_warn "opencode.jsonc not found"
fi

print_header "Dotfiles collected successfully!"
print_info "Don't forget to commit and push changes!"
