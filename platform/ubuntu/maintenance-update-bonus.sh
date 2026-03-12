#!/bin/bash
# Update Checker for .deb-based Tools
# Checks for updates to .deb tools and installs if confirmed.
# See README.md for usage and adding new tools.

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

declare -r SCRIPT_VERSION="1.1.0"
declare -r TEMP_DIR="/tmp/update-bonus-tools-$$"

# -----------------------------------------------------------------------
# DEB Tools Configuration (GitHub Releases)
# -----------------------------------------------------------------------
# Format: GITHUB_REPO|PACKAGE_NAME|DEB_FILENAME_PATTERN
#
# To add a new tool, just add an entry to this array. No function edits needed.
# Remember to also add to install-bonus-tools.sh DEB_TOOLS array.
# -----------------------------------------------------------------------
declare -A DEB_TOOLS=(
    ["Super Productivity"]="johannesjo/super-productivity|superproductivity|superProductivity-amd64.deb"
    ["Obsidian"]="obsidianmd/obsidian-releases|obsidian|obsidian_.*_amd64.deb"
)

UPDATED_COUNT=0
SKIPPED_COUNT=0
UPTODATE_COUNT=0
AUTO_UPDATE=0

print_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
print_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
print_header()  { echo -e "${CYAN}=== $1 ===${NC}"; }

check_prerequisites() {
    local missing=()
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Install with: sudo apt install ${missing[*]}"
        exit 1
    fi
}

get_installed_version() {
    local package_name="$1"

    if dpkg -s "$package_name" >/dev/null 2>&1; then
        dpkg -s "$package_name" | grep -E '^Version:' | awk '{print $2}' | sed 's/-.*//'
    else
        echo "not_installed"
    fi
}

# Fetch release data from GitHub API. Returns JSON on stdout.
# Sets the caller's variable via nameref to avoid subshell issues.
fetch_release_data() {
    local github_repo="$1"

    local api_url="https://api.github.com/repos/${github_repo}/releases/latest"
    local release_data
    release_data=$(curl -fsSL "$api_url") || {
        print_error "  GitHub API request failed (rate limit or network error)"
        return 1
    }

    # Check for API error responses (rate limiting, not found, etc.)
    local api_message
    api_message=$(echo "$release_data" | jq -r '.message // empty')
    if [[ -n "$api_message" ]]; then
        print_error "  GitHub API: $api_message"
        return 1
    fi

    echo "$release_data"
}

get_latest_version() {
    local release_data="$1"

    local tag_name
    tag_name=$(echo "$release_data" | jq -r '.tag_name // empty')

    if [[ -z "$tag_name" ]]; then
        print_error "  Could not determine latest version"
        return 1
    fi

    echo "${tag_name#v}"
}

compare_versions() {
    local installed="$1"
    local latest="$2"

    if [[ "$installed" == "not_installed" ]]; then
        echo "update_available"
        return
    fi

    if [[ "$installed" != "$latest" ]]; then
        echo "update_available"
    else
        echo "up_to_date"
    fi
}

download_deb() {
    local release_data="$1"
    local deb_pattern="$2"
    local output_file="$3"

    local deb_url
    deb_url=$(echo "$release_data" | jq -r --arg pattern "$deb_pattern" \
        '.assets[] | select(.name | test($pattern)) | .browser_download_url' | head -n1)

    if [[ -z "$deb_url" ]]; then
        print_error "  No .deb found matching pattern: $deb_pattern"
        return 1
    fi

    print_info "  Downloading: $(basename "$deb_url")..."
    curl -fSL --progress-bar -o "$output_file" "$deb_url"
}

install_deb() {
    local deb_file="$1"

    print_info "  Installing..."
    sudo dpkg -i "$deb_file" || sudo apt install -f -y
}

prompt_user() {
    if [[ "$AUTO_UPDATE" -eq 1 ]]; then
        return 0
    fi

    local answer
    read -rp "  Update? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

list_tools() {
    print_header "Tracked .deb Tools"

    for tool_name in "${!DEB_TOOLS[@]}"; do
        IFS='|' read -r github_repo package_name deb_pattern <<< "${DEB_TOOLS[$tool_name]}"
        local installed_ver
        installed_ver=$(get_installed_version "$package_name")

        echo -e "${GREEN}•${NC} $tool_name"
        echo -e "  Package: $package_name"
        echo -e "  Repo: $github_repo"
        echo -e "  Current: ${CYAN}$installed_ver${NC}"
        echo
    done
}

check_and_update_tool() {
    local display_name="$1"
    IFS='|' read -r github_repo package_name deb_pattern <<< "${DEB_TOOLS[$display_name]}"

    print_info "Checking $display_name..."

    local installed_ver
    installed_ver=$(get_installed_version "$package_name")

    # Single API call -- reuse for both version check and download
    local release_data
    release_data=$(fetch_release_data "$github_repo") || return 0

    local latest_ver
    latest_ver=$(get_latest_version "$release_data") || return 0

    local status
    status=$(compare_versions "$installed_ver" "$latest_ver")

    if [[ "$status" == "up_to_date" ]]; then
        print_info "  [${GREEN}UP TO DATE${NC}] $installed_ver"
        UPTODATE_COUNT=$((UPTODATE_COUNT + 1))
        return 0
    fi

    print_info "  Installed: ${CYAN}$installed_ver${NC}"
    print_info "  Latest:    ${CYAN}$latest_ver${NC}"
    print_info "  [${YELLOW}UPDATE AVAILABLE${NC}]"

    if prompt_user; then
        local deb_file="$TEMP_DIR/${package_name}_update.deb"

        if download_deb "$release_data" "$deb_pattern" "$deb_file" && install_deb "$deb_file"; then
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
            print_info "  ${GREEN}Updated to $latest_ver${NC}"
        else
            print_error "  Update failed"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
    else
        print_info "  Skipped"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
}

print_summary() {
    print_header "Update Summary"
    echo -e "${GREEN}Updated:${NC}    $UPDATED_COUNT"
    echo -e "${YELLOW}Skipped:${NC}    $SKIPPED_COUNT"
    echo -e "${GREEN}Up-to-date:${NC} $UPTODATE_COUNT"
}

cleanup() {
    rm -rf "$TEMP_DIR"
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list) check_prerequisites; list_tools; exit 0 ;;
            --auto) AUTO_UPDATE=1; shift ;;
            *)      print_error "Unknown flag: $1"; exit 1 ;;
        esac
    done

    check_prerequisites
    mkdir -p "$TEMP_DIR"

    print_header "Checking tools for updates..."
    echo

    for tool_name in "${!DEB_TOOLS[@]}"; do
        check_and_update_tool "$tool_name"
        echo
    done

    print_summary
}

trap cleanup EXIT

main "$@"
