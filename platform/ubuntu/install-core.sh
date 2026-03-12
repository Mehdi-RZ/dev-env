#!/bin/bash
# Core Development Tools Installation
# Installs: git, zsh, vim, docker, uv, aws-cli, kubectl, kind, helm, opentofu

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"
source "$SCRIPT_DIR/../../lib/utils.sh"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- Sudo check ---
require_sudo

print_header "Core Development Tools Installation"

print_step "Update & Upgrade system packages..."
sudo apt update && sudo apt upgrade -y

mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

print_step "Installing base packages..."
sudo apt -y install \
    build-essential \
    curl wget \
    git \
    zsh vim \
    python3 python3-venv \
    unzip zip gzip tar \
    glibc-source groff less \
    ca-certificates

print_step "Installing uv..."
if command_exists uv; then
    print_info "uv already installed, skipping"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

print_step "Installing Docker..."
if command_exists docker; then
    print_info "Docker already installed, skipping"
else
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    sudo apt update
    
    # Install Docker packages
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    print_info "Please log out and back in to use Docker as non-root"
fi

print_step "Installing AWS CLI..."
if command_exists aws; then
    print_info "AWS CLI already installed, skipping"
else
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TEMP_DIR/awscliv2.zip"
    unzip -q "$TEMP_DIR/awscliv2.zip" -d "$TEMP_DIR"
    sudo "$TEMP_DIR/aws/install"
fi

print_step "Installing kubectl..."
if command_exists kubectl; then
    print_info "kubectl already installed, skipping"
else
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL -o "$TEMP_DIR/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    curl -fsSL -o "$TEMP_DIR/kubectl.sha256" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat "$TEMP_DIR/kubectl.sha256")  $TEMP_DIR/kubectl" | sha256sum --check
    chmod +x "$TEMP_DIR/kubectl"
    mv "$TEMP_DIR/kubectl" ~/.local/bin/kubectl
fi

print_step "Installing kind..."
if command_exists kind; then
    print_info "kind already installed, skipping"
else
    LATEST=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
        | grep '"tag_name":' \
        | sed -E 's/.*"([^"]+)".*/\1/')
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  KIND_ARCH="amd64" ;;
        aarch64) KIND_ARCH="arm64" ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    curl -fsSL -o "$TEMP_DIR/kind" "https://kind.sigs.k8s.io/dl/${LATEST}/kind-linux-${KIND_ARCH}"
    chmod +x "$TEMP_DIR/kind"
    mv "$TEMP_DIR/kind" ~/.local/bin/kind
fi

print_step "Installing Helm..."
if command_exists helm; then
    print_info "Helm already installed, skipping"
else
    curl -fsSL -o "$TEMP_DIR/get_helm.sh" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 "$TEMP_DIR/get_helm.sh"
    "$TEMP_DIR/get_helm.sh"
fi

print_step "Installing OpenTofu..."
if command_exists tofu; then
    print_info "OpenTofu already installed, skipping"
else
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o "$TEMP_DIR/install-opentofu.sh"
    chmod +x "$TEMP_DIR/install-opentofu.sh"
    "$TEMP_DIR/install-opentofu.sh" --install-method deb
fi

print_step "Cleaning up..."
sudo apt -y autoremove
sudo apt -y autoclean

print_header "Core tools installation complete!"
print_info "Note: Log out and back in to use Docker as non-root user"
