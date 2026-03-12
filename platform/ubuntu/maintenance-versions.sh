#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# helper function to print version or "not installed"
version_or_missing() {
    local cmd=$1
    local name=$2
    if command -v "$cmd" >/dev/null 2>&1; then
        # some commands need special flags for version
        case "$cmd" in
            docker|podman|vim)
                echo "$name: $($cmd --version | head -n1)"
                ;;
            unzip)
                echo "$name: $($cmd -v 2>&1 | head -n1)"
                ;;
            kind)
                echo "$name: $($cmd --version 2>/dev/null || echo unknown)"
                ;;
            aws)
                echo "$name: $($cmd --version 2>/dev/null)"
                ;;
            kubectl)
                echo "$name: $($cmd version --client 2>/dev/null | head -n1)"
                ;;
            helm)
                echo "$name: $($cmd version --short 2>/dev/null)"
                ;;
            uv)
                echo "$name: $($cmd --version 2>/dev/null || echo unknown)"
                ;;
            tofu)
                echo "$name: $($cmd version 2>/dev/null | head -n1 || echo unknown)"
                ;;
            *)
                echo "$name: $($cmd --version 2>/dev/null || $cmd -v 2>/dev/null || echo unknown)"
                ;;
        esac
    else
        echo "$name: not installed"
    fi
}

echo "====== Dev Environment Version Check ======"
version_or_missing git "Git"
version_or_missing zsh "Zsh"
version_or_missing vim "Vim"
version_or_missing python3 "Python3"
version_or_missing pip3 "Pip3"
# version_or_missing curl "Curl"
# version_or_missing wget "Wget"
version_or_missing unzip "Unzip"
version_or_missing docker "Docker"
version_or_missing podman "Podman"
version_or_missing docker-compose "Docker Compose (V1)"
# Docker Compose V2 is a plugin (docker compose), not a standalone binary
if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose (V2): $(docker compose version 2>/dev/null)"
else
    echo "Docker Compose (V2): not installed"
fi
version_or_missing uv "UV"
version_or_missing aws "AWS CLI"
version_or_missing kubectl "Kubectl"
version_or_missing kind "Kind"
version_or_missing helm "Helm"
version_or_missing tofu "OpenTofu"
version_or_missing node "Node.js"
version_or_missing npm "NPM"

echo "=========================================="
