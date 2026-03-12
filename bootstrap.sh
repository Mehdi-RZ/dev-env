#!/bin/bash
# Bootstrap Script
# One-command setup: installs Taskfile and runs initial setup

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"

print_header "Dev Environment Bootstrap"

# Check if Taskfile is installed
if command -v task >/dev/null 2>&1; then
    print_info "Taskfile already installed: $(task --version)"
else
    print_info "Installing Taskfile..."
    
    # Install Taskfile using official Cloudsmith method
    curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | sudo -E bash
    sudo apt install -y task
    
    if command -v task >/dev/null 2>&1; then
        print_info "Taskfile installed successfully: $(task --version)"
    else
        print_error "Failed to install Taskfile"
        exit 1
    fi
fi

# Show available tasks
print_header "Available Setup Options"
echo ""
task --list
echo ""

# Ask user what to install
print_info "What would you like to install?"
echo "  1) Desktop setup (all tools + GUI apps)"
echo "  2) Core setup (no GUI apps - for servers/VMs)"
echo "  3) Skip - I'll run tasks manually"
echo ""
read -p "Choice [1-3]: " choice

case "$choice" in
    1)
        print_header "Running desktop setup..."
        task setup:desktop
        ;;
    2)
        print_header "Running core setup..."
        task setup:core
        ;;
    3)
        print_info "Skipping automatic setup"
        print_info "Run 'task --list' to see available commands"
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_header "Bootstrap complete!"
print_info "Run 'task --list' to see all available commands"
