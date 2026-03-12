#!/bin/bash
# Diff Dotfiles
# Show differences between repo configs and home directory configs

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

REPO_ROOT="$SCRIPT_DIR/../.."
CONFIG_DIR="$REPO_ROOT/configs"

print_header "Dotfiles Diff"

HAS_DIFF=0

# Function to show diff
show_diff() {
    local repo_file="$1"
    local home_file="$2"
    local name="$3"
    
    if [ ! -f "$repo_file" ]; then
        print_warn "$name: Not in repo"
        return
    fi
    
    if [ ! -f "$home_file" ]; then
        print_warn "$name: Not in home directory"
        return
    fi
    
    if diff -q "$repo_file" "$home_file" > /dev/null 2>&1; then
        print_info "$name: No changes"
    else
        print_step "$name: Changes detected"
        diff -u "$repo_file" "$home_file" || true
        echo ""
        HAS_DIFF=1
    fi
}

# Check each config file
show_diff "$CONFIG_DIR/.gitconfig" ~/.gitconfig ".gitconfig"
show_diff "$CONFIG_DIR/.vim/vimrc" ~/.vimrc ".vimrc"
show_diff "$CONFIG_DIR/kitty.conf" ~/.config/kitty/kitty.conf "kitty.conf"
show_diff "$CONFIG_DIR/.docker/config.json" ~/.docker/config.json "docker/config.json"
show_diff "$CONFIG_DIR/main_profile_linux.code-profile" ~/.config/Code/User/profiles/main_profile_linux.code-profile "VSCode profile (Linux)"
show_diff "$CONFIG_DIR/main_profile_wsl.code-profile" ~/.config/Code/User/profiles/main_profile_wsl.code-profile "VSCode profile (WSL)"
show_diff "$CONFIG_DIR/agents-env/opencode/opencode.jsonc" ~/.config/opencode/opencode.jsonc "opencode.jsonc"

if [ $HAS_DIFF -eq 0 ]; then
    print_header "All dotfiles in sync!"
else
    print_header "Differences found"
    print_info "Run 'task dotfiles:collect' to sync changes back to repo"
fi
