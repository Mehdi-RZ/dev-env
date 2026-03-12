#!/bin/bash
# Common utility functions
# Source this file in scripts: source "$(dirname "$0")/../lib/utils.sh"

# Check if a package is installed
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Require sudo privileges
require_sudo() {
    if ! sudo -v 2>/dev/null; then
        print_error "This script requires sudo privileges"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install GPG key for APT repositories
install_gpg_key() {
    local key_url="$1"
    local keyring="$2"

    if [[ -f "$keyring" ]]; then
        return 0
    fi

    print_info "Installing GPG key: $(basename "$keyring")..."

    local tmp_key
    tmp_key=$(mktemp)
    curl -fsSL "$key_url" -o "$tmp_key"

    # Dearmor only if the key is ASCII-armored; binary keys are used as-is
    if file "$tmp_key" | grep -qi "pgp public key block"; then
        sudo gpg --dearmor -o "$keyring" < "$tmp_key"
    else
        sudo cp "$tmp_key" "$keyring"
    fi

    rm -f "$tmp_key"
    sudo chmod 644 "$keyring"
}

# Replace {VERSION} and {CODENAME} placeholders with actual Ubuntu values
expand_placeholders() {
    local str="$1"
    local version codename
    version=$(lsb_release -rs)
    codename=$(lsb_release -cs)
    str="${str//\{VERSION\}/$version}"
    str="${str//\{CODENAME\}/$codename}"
    echo "$str"
}

# Get package name from config entry (last pipe-separated field)
get_package() {
    echo "${1##*|}"
}

# Get type from config entry (first pipe-separated field)
get_type() {
    echo "${1%%|*}"
}
