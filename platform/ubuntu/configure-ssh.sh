#!/bin/bash
# SSH Key Configuration
# Generates new SSH keys or copies existing ones from a specified path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"

declare -r SCRIPT_VERSION="1.0.0"
declare -r SSH_DIR="$HOME/.ssh"

print_header "SSH Key Configuration"

check_ssh_dir() {
    if [[ ! -d "$SSH_DIR" ]]; then
        mkdir -p "$SSH_DIR"
        print_info "Created $SSH_DIR"
    fi
}

get_existing_keys() {
    find "$SSH_DIR" -maxdepth 1 -type f \( -name "id_*" ! -name "*.pub" ! -name "known_hosts" ! -name "config" ! -name "authorized_keys" \) 2>/dev/null
}

list_existing_keys() {
    local keys
    keys=$(get_existing_keys)
    if [[ -n "$keys" ]]; then
        echo -e "\n${CYAN}Existing keys found in $SSH_DIR:${NC}"
        for key in $keys; do
            local keyname
            keyname=$(basename "$key")
            local keytype
            keytype=$(ssh-keygen -l -f "$key" 2>/dev/null | awk '{print $NF}' || echo "unknown")
            echo -e "  ${GREEN}•${NC} $keyname ($keytype)"
        done
        echo ""
    fi
}

prompt_key_type() {
    echo -e "${CYAN}Select key type:${NC}"
    echo -e "  ${GREEN}1${NC}) Ed25519 (recommended)"
    echo -e "  ${GREEN}2${NC}) RSA 4096"
    echo -n "Choice [1]: "
    read -r choice
    case "$choice" in
        2) echo "rsa" ;;
        *) echo "ed25519" ;;
    esac
}

prompt_key_path() {
    echo -n "Enter source path for SSH key: "
    read -r src_path
    src_path=$(eval echo "$src_path")
    echo -n "Enter source path for public key [.pub]: "
    read -r src_pub_path
    src_pub_path=$(eval echo "$src_pub_path")

    if [[ ! -f "$src_path" ]]; then
        print_error "Key file not found: $src_path"
        return 1
    fi

    if [[ ! -f "$src_pub_path" ]]; then
        print_error "Public key file not found: $src_pub_path"
        return 1
    fi

    echo "$src_path:$src_pub_path"
}

generate_key() {
    local key_path="$1"
    local key_type="$2"

    if [[ -f "$key_path" ]]; then
        print_warn "Key already exists: $key_path"
        echo -n "Overwrite? [y/N] "
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            print_info "Skipped"
            return 0
        fi
    fi

    echo -n "Enter key comment [e.g. user@machine]: "
    read -r comment

    print_info "Generating $key_type key: $key_path"
    ssh-keygen -t "$key_type" -f "$key_path" -C "$comment" -N ""

    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"

    print_info "Public key:"
    cat "${key_path}.pub"
    echo ""
}

copy_key() {
    local src_key="$1"
    local src_pub="$2"
    local dest_name="$3"

    local dest_key="$SSH_DIR/$dest_name"
    local dest_pub="$SSH_DIR/${dest_name}.pub"

    if [[ -f "$dest_key" ]]; then
        print_warn "Key already exists: $dest_key"
        echo -n "Overwrite? [y/N] "
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            print_info "Skipped"
            return 0
        fi
    fi

    print_info "Copying key from $src_key -> $dest_key"
    cp "$src_key" "$dest_key"
    cp "$src_pub" "$dest_pub"

    chmod 600 "$dest_key"
    chmod 644 "$dest_pub"

    print_info "Key installed successfully"
    print_info "Public key:"
    cat "$dest_pub"
    echo ""
}

main() {
    check_ssh_dir
    list_existing_keys

    local existing_keys
    existing_keys=$(get_existing_keys | wc -l)

    if [[ "$existing_keys" -gt 0 ]]; then
        echo -e "${CYAN}SSH keys are already configured. What would you like to do?${NC}"
    else
        echo -e "${CYAN}No SSH keys found. How would you like to proceed?${NC}"
    fi

    echo -e "  ${GREEN}1${NC}) Generate new SSH key"
    echo -e "  ${GREEN}2${NC}) Copy key from existing path"
    echo -e "  ${GREEN}s${NC}) Skip / exit"
    echo -n "Choice [s]: "
    read -r action

    case "$action" in
        1)
            echo -n "Enter key name (without .pub) [id_ed25519]: "
            read -r key_name
            key_name="${key_name:-id_ed25519}"
            key_path="$SSH_DIR/$key_name"

            key_type=$(prompt_key_type)
            generate_key "$key_path" "$key_type"
            ;;
        2)
            local paths
            paths=$(prompt_key_path) || exit 1
            IFS=':' read -r src_key src_pub <<< "$paths"

            local dest_name
            echo -n "Enter destination key name [$(basename "$src_key")]: "
            read -r dest_name
            dest_name="${dest_name:-$(basename "$src_key")}"

            copy_key "$src_key" "$src_pub" "$dest_name"
            ;;
        *)
            print_info "Skipped SSH key configuration"
            ;;
    esac

    print_header "SSH configuration complete!"
}

main "$@"
