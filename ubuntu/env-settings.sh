#!/bin/bash
set -euo pipefail

echo "Configuring OhMyZsh..."
echo ---------------------------------------------------------
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i "/^plugins=/c\plugins=(git aws zsh-autosuggestions zsh-syntax-highlighting)" ~/.zshrc
chsh -s /usr/bin/zsh

# Docker's Host rootless setup : https://brandonrozek.com/blog/rootless-docker-compose-podman/
# echo "Configuring Podman service ..."
# systemctl --user enable podman.socket
# systemctl --user start podman.socket

# .zshrc custom configs
cat <<EOF | tee -a ~/.zshrc
export PATH=\$PATH:\$HOME/.local/bin
# if using podman
# export DOCKER_HOST=unix:///run/user/\$UID/podman/podman.sock

alias ll="ls -alh"
EOF
