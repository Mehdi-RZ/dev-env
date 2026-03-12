#!/bin/bash
# Shell Configuration
# Installs and configures oh-my-zsh with plugins

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"
source "$SCRIPT_DIR/../../lib/utils.sh"

print_header "Shell Configuration"

print_step "Installing oh-my-zsh..."
if [ -d ~/.oh-my-zsh ]; then
    print_info "oh-my-zsh already installed, skipping"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

print_step "Installing zsh plugins..."

# zsh-autosuggestions
if [ -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    print_info "zsh-autosuggestions already installed, skipping"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    print_info "zsh-syntax-highlighting already installed, skipping"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

print_step "Configuring zsh plugins..."
sed -i "/^plugins=/c\plugins=(git aws zsh-autosuggestions zsh-syntax-highlighting)" ~/.zshrc

print_step "Adding custom configurations to .zshrc..."
# Check if custom config already exists
if ! grep -q "export PATH=\$PATH:\$HOME/.local/bin" ~/.zshrc; then
    cat <<'EOF' >> ~/.zshrc

# Custom configurations
export PATH=$PATH:$HOME/.local/bin

# Aliases
alias ll="ls -alh"
EOF
    print_info "Custom configurations added"
else
    print_info "Custom configurations already present, skipping"
fi

print_step "Changing default shell to zsh..."
if [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "/bin/zsh" ]; then
    print_info "Default shell is already zsh"
else
    chsh -s /usr/bin/zsh
    print_info "Default shell changed to zsh (restart session to take effect)"
fi

print_header "Shell configuration complete!"
print_info "Please restart your terminal or run: exec zsh"
