#!/bin/bash
# GUI Applications Installer
# Installs GUI tools from official APT repos and GitHub releases.

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/colors.sh"
source "$SCRIPT_DIR/../../lib/utils.sh"

# === CONFIGURATION ===
declare -r SCRIPT_VERSION="1.3.0"
declare -r TEMP_DIR="/tmp/bonus-tools-install-$$"
declare -r KEYRINGS_DIR="/usr/share/keyrings"

# Check WORK environment variable
WORK_MODE="${WORK:-false}"

# -----------------------------------------------------------------------
# APT Tools Configuration - PERSONAL (always installed)
# -----------------------------------------------------------------------
# Format: TYPE|...fields...|PACKAGE_NAME  (package is always last)
#
# Supported types:
#
#   repo|GPG_KEY_URL|REPO_URL|DISTRIBUTION|PACKAGE_NAME
#     Standard APT repository with a signed GPG key.
#     Keyring:  /usr/share/keyrings/<PACKAGE_NAME>-archive-keyring.gpg
#     Produces: deb [arch=amd64 signed-by=<keyring>] <REPO_URL> <DISTRIBUTION> main
#     REPO_URL supports placeholders: {VERSION} -> Ubuntu version (e.g. 24.04)
#                                     {CODENAME} -> Ubuntu codename (e.g. noble)
#     DISTRIBUTION can also use {CODENAME}, or a fixed string like "stable".
#
#   ppa|PPA_STRING|PACKAGE_NAME
#     Launchpad PPA (keys managed automatically by add-apt-repository).
#
#   sources|GPG_KEY_URL|SOURCES_DOWNLOAD_URL|PACKAGE_NAME
#     Download a pre-built .sources file (e.g. Brave).
#     Keyring:  /usr/share/keyrings/<PACKAGE_NAME>-archive-keyring.gpg
#     The .sources file is saved as-is to /etc/apt/sources.list.d/
# -----------------------------------------------------------------------
declare -A APT_TOOLS_PERSONAL=(
    ["brave-browser"]="sources|https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg|https://brave-browser-apt-release.s3.brave.com/brave-browser.sources|brave-browser"
    ["code"]="repo|https://packages.microsoft.com/keys/microsoft.asc|https://packages.microsoft.com/repos/code|stable|code"
    ["keepassxc"]="ppa|ppa:phoerious/keepassxc|keepassxc"
)

# -----------------------------------------------------------------------
# APT Tools Configuration - WORK (only installed when WORK=true)
# -----------------------------------------------------------------------
declare -A APT_TOOLS_WORK=(
    ["microsoft-edge-stable"]="repo|https://packages.microsoft.com/keys/microsoft.asc|https://packages.microsoft.com/repos/edge|stable|microsoft-edge-stable"
    ["intune-portal"]="repo|https://packages.microsoft.com/keys/microsoft.asc|https://packages.microsoft.com/ubuntu/{VERSION}/prod|{CODENAME}|intune-portal"
    ["slack-desktop"]="repo|https://packagecloud.io/slacktechnologies/slack/gpgkey|https://packagecloud.io/slacktechnologies/slack/debian|jessie|slack-desktop"
)

# -----------------------------------------------------------------------
# DEB Tools Configuration (GitHub Releases) - always installed
# -----------------------------------------------------------------------
# Format: GITHUB_REPO|PACKAGE_NAME|DEB_FILENAME_PATTERN
#
#   GITHUB_REPO          - owner/repo on GitHub
#   PACKAGE_NAME         - dpkg package name (used for install check)
#   DEB_FILENAME_PATTERN - regex matching the .deb asset filename
# -----------------------------------------------------------------------
declare -A DEB_TOOLS=(
    ["Super Productivity"]="johannesjo/super-productivity|superproductivity|superProductivity-amd64.deb"
    ["Obsidian"]="obsidianmd/obsidian-releases|obsidian|obsidian_.*_amd64.deb"
)

# Merge APT_TOOLS based on WORK mode
declare -A APT_TOOLS
for key in "${!APT_TOOLS_PERSONAL[@]}"; do
    APT_TOOLS[$key]="${APT_TOOLS_PERSONAL[$key]}"
done

if [[ "$WORK_MODE" == "true" ]]; then
    for key in "${!APT_TOOLS_WORK[@]}"; do
        APT_TOOLS[$key]="${APT_TOOLS_WORK[$key]}"
    done
fi

# === FUNCTIONS ===

check_prerequisites() {
    print_step "Checking prerequisites..."

    require_sudo

    local missing=()
    for cmd in curl gpg jq lsb_release add-apt-repository; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Install with: sudo apt install ${missing[*]}"
        exit 1
    fi

    print_info "All prerequisites met"
}

install_gpg_keys() {
    print_step "Installing GPG keys..."

    local -A done_keyrings=()

    for tool in "${!APT_TOOLS[@]}"; do
        local entry="${APT_TOOLS[$tool]}"
        local type
        type=$(get_type "$entry")
        local package
        package=$(get_package "$entry")

        [[ "$type" == "ppa" ]] && continue

        local gpg_key_url
        IFS='|' read -r _ gpg_key_url _ <<< "$entry"

        local keyring="${KEYRINGS_DIR}/${package}-archive-keyring.gpg"

        # Skip if already processed this exact keyring file
        if [[ -n "${done_keyrings[$keyring]+x}" ]]; then
            continue
        fi
        done_keyrings[$keyring]=1

        install_gpg_key "$gpg_key_url" "$keyring"
    done

    print_info "GPG keys installed"
}

add_apt_repositories() {
    print_step "Adding APT repositories..."

    for tool in "${!APT_TOOLS[@]}"; do
        local entry="${APT_TOOLS[$tool]}"
        local type
        type=$(get_type "$entry")
        local package
        package=$(get_package "$entry")

        case "$type" in
            repo)
                local gpg_key_url repo_url distribution
                IFS='|' read -r _ gpg_key_url repo_url distribution _ <<< "$entry"

                local sources_file="/etc/apt/sources.list.d/${tool}.list"
                [[ -f "$sources_file" ]] && continue

                local keyring="${KEYRINGS_DIR}/${package}-archive-keyring.gpg"
                repo_url=$(expand_placeholders "$repo_url")
                distribution=$(expand_placeholders "$distribution")

                print_info "Adding repo for ${tool}..."
                echo "deb [arch=amd64 signed-by=${keyring}] ${repo_url} ${distribution} main" \
                    | sudo tee "$sources_file" >/dev/null
                ;;

            ppa)
                local ppa_string
                IFS='|' read -r _ ppa_string _ <<< "$entry"

                if grep -rq "${ppa_string#ppa:}" /etc/apt/sources.list.d/ 2>/dev/null; then
                    continue
                fi

                print_info "Adding PPA for ${tool}..."
                sudo add-apt-repository -y --no-update "$ppa_string"
                ;;

            sources)
                local sources_url
                IFS='|' read -r _ _ sources_url _ <<< "$entry"

                local sources_file="/etc/apt/sources.list.d/${tool}.sources"
                [[ -f "$sources_file" ]] && continue

                print_info "Adding sources for ${tool}..."
                sudo curl -fsSL "$sources_url" -o "$sources_file"
                ;;

            *)
                print_warn "Unknown APT tool type '${type}' for ${tool}, skipping..."
                ;;
        esac
    done

    print_info "APT repositories configured"
}

install_apt_tools() {
    print_step "Updating package list..."
    sudo apt update

    print_step "Installing APT tools..."

    for tool in "${!APT_TOOLS[@]}"; do
        local package
        package=$(get_package "${APT_TOOLS[$tool]}")

        if is_installed "$package"; then
            print_info "$package already installed, skipping..."
            continue
        fi

        print_info "Installing $package..."
        sudo DEBIAN_FRONTEND=noninteractive apt install -y "$package"
    done

    print_info "APT tools installed"
}

download_latest_deb() {
    local github_repo="$1"
    local deb_pattern="$2"
    local output_file="$3"

    print_info "Fetching latest release from $github_repo..."

    local api_url="https://api.github.com/repos/${github_repo}/releases/latest"
    local release_data
    release_data=$(curl -fsSL "$api_url") || {
        print_error "GitHub API request failed (rate limit or network error)"
        return 1
    }

    local api_message
    api_message=$(echo "$release_data" | jq -r '.message // empty')
    if [[ -n "$api_message" ]]; then
        print_error "GitHub API: $api_message"
        return 1
    fi

    local deb_url
    deb_url=$(echo "$release_data" | jq -r --arg pattern "$deb_pattern" \
        '.assets[] | select(.name | test($pattern)) | .browser_download_url' | head -n1)

    if [[ -z "$deb_url" ]]; then
        print_error "No .deb file found matching pattern: $deb_pattern"
        return 1
    fi

    print_info "Downloading $(basename "$deb_url")..."
    curl -fSL --progress-bar -o "$output_file" "$deb_url"

    print_info "Downloaded: $(basename "$output_file") ($(du -h "$output_file" | cut -f1))"
}

install_deb_tools() {
    print_step "Installing .deb tools..."

    mkdir -p "$TEMP_DIR"

    for tool_name in "${!DEB_TOOLS[@]}"; do
        IFS='|' read -r github_repo package_name deb_pattern <<< "${DEB_TOOLS[$tool_name]}"

        if is_installed "$package_name"; then
            print_info "$tool_name ($package_name) already installed, skipping..."
            continue
        fi

        print_info "Installing $tool_name ($package_name)..."

        local deb_file="$TEMP_DIR/${package_name}_latest.deb"

        if ! download_latest_deb "$github_repo" "$deb_pattern" "$deb_file"; then
            print_warn "Failed to download $tool_name, skipping..."
            continue
        fi

        sudo dpkg -i "$deb_file" || sudo apt install -f -y
        rm -f "$deb_file"
    done

    print_info ".deb tools installed"
}

verify_installations() {
    print_step "Verifying installations..."

    local failed=()

    for tool in "${!APT_TOOLS[@]}"; do
        local package
        package=$(get_package "${APT_TOOLS[$tool]}")
        if ! is_installed "$package"; then
            failed+=("$package")
        fi
    done

    for tool_name in "${!DEB_TOOLS[@]}"; do
        IFS='|' read -r _ package_name _ <<< "${DEB_TOOLS[$tool_name]}"
        if ! is_installed "$package_name"; then
            failed+=("$package_name")
        fi
    done

    if [[ ${#failed[@]} -eq 0 ]]; then
        print_info "All tools installed successfully!"
    else
        print_error "Failed to install: ${failed[*]}"
        return 1
    fi
}

cleanup() {
    rm -rf "$TEMP_DIR"
}

main() {
    print_header "GUI Applications Installer v${SCRIPT_VERSION}"

    if [[ "$WORK_MODE" == "true" ]]; then
        print_info "Work mode: ON - Installing personal + work tools"
    else
        print_info "Work mode: OFF - Installing personal tools only"
    fi
    echo ""

    check_prerequisites
    install_gpg_keys
    add_apt_repositories
    install_apt_tools
    install_deb_tools
    verify_installations

    print_header "GUI applications installation complete!"
}

trap cleanup EXIT

main "$@"
