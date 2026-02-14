#!/bin/bash
set -euo pipefail

echo "Update & Upgrade ..."
echo ---------------------------------------------------------
sudo apt update && sudo apt upgrade -y

mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

echo "installing base packages ..."
echo ---------------------------------------------------------
sudo apt -y install \
    build-essential \
    curl wget \
    git \
    zsh vim \
    python3 python3-venv \
    unzip zip gzip tar \
    glibc-source groff less \
    ca-certificates
    # podman podman-docker docker-compose \


echo "installing uv ..."
echo ---------------------------------------------------------
if command -v uv > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi


echo "installing docker ..."
echo ---------------------------------------------------------
if command -v docker > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    # Add Docker's official GPG key:
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/ubuntu
    Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
    Components: stable
    Signed-By: /etc/apt/keyrings/docker.asc
EOF
    sudo apt update
    # install docker packages
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
fi


echo "installing aws-cli ..."
echo ---------------------------------------------------------
if command -v aws > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi


echo "installing kubectl..."
echo ---------------------------------------------------------
if command -v kubectl > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    chmod +x kubectl
    mv ./kubectl ~/.local/bin/kubectl
    rm -f kubectl.sha256
fi


echo "installing kind ..."
echo ---------------------------------------------------------
if command -v kind > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    LATEST=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
        | grep '"tag_name":' \
        | sed -E 's/.*"([^"]+)".*/\1/')
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/${LATEST}/kind-linux-amd64
    chmod +x kind
    mv kind ~/.local/bin/kind
fi


echo "installing helm ..."
echo ---------------------------------------------------------
if command -v helm > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm -f ./get_helm.sh
fi


echo "installing OpenTofu ..."
echo ---------------------------------------------------------
if command -v tofu > /dev/null 2>&1; then
    echo "... already installed, skipping"
else
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    rm -f install-opentofu.sh
fi


echo "installing OhMyZsh ..."
echo ---------------------------------------------------------
if [ -d ~/.oh-my-zsh ]; then    
    echo "... already installed, skipping"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi


echo "cleaning up ..."
echo ---------------------------------------------------------
sudo apt -y autoremove
sudo apt -y autoclean

echo "infos ..."
echo "Please log out and back in to use Docker as non-root."