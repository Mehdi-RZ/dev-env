#!/bin/bash
# Color output utilities
# Source this file in scripts: source "$(dirname "$0")/../lib/colors.sh"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

print_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
print_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
print_step()    { echo -e "${GREEN}[STEP]${NC} $*"; }
print_header()  { echo -e "${CYAN}=== $1 ===${NC}"; }
