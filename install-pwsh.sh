#!/bin/bash
# PowerShell installation script with strict mode and functional approach

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Log function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
handle_error() {
  local line=$1
  local command=$2
  local code=$3
  log "ERROR at line ${line}: Command '${command}' exited with status ${code}"
  exit 1
}

# Set trap for errors
trap 'handle_error ${LINENO} "$BASH_COMMAND" $?' ERR

# Check if PowerShell is already installed
check_existing_installation() {
  log "Checking if PowerShell is already installed"
  if command -v pwsh >/dev/null 2>&1; then
    local VERSION
    VERSION=$(pwsh -c '$PSVersionTable.PSVersion.ToString()' 2>/dev/null)
    log "PowerShell $VERSION is already installed"
    log "Installation skipped. Exiting..."
    exit 0
  fi
  log "PowerShell not found, proceeding with installation"
}

# Update repositories function
update_repos() {
  log "Updating package repositories"
  apt update
}

# Install prerequisites function
install_prerequisites() {
  log "Installing prerequisites"
  apt install -y wget apt-transport-https software-properties-common
}

# Get OS version function
get_os_version() {
  log "Detecting Ubuntu version"
  source /etc/os-release
  if [[ -z "${VERSION_ID:-}" ]]; then
    log "ERROR: Could not determine Ubuntu version"
    exit 1
  fi
  log "Detected Ubuntu $VERSION_ID"
  return 0
}

# Add Microsoft repository function
add_ms_repo() {
  local repo_package="packages-microsoft-prod.deb"
  log "Adding Microsoft repository"
  wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/$repo_package"
  dpkg -i "$repo_package"
  rm "$repo_package"
}

# Install PowerShell function
install_powershell() {
  log "Installing PowerShell"
  apt install -y powershell
}

# Verify installation function
verify_installation() {
  log "Verifying installation"
  if ! command -v pwsh >/dev/null 2>&1; then
    log "ERROR: PowerShell installed but 'pwsh' command not found in PATH"
    exit 1
  fi
  
  local VERSION
  VERSION=$(pwsh -c '$PSVersionTable.PSVersion.ToString()' 2>/dev/null)
  log "PowerShell $VERSION installed successfully"
}

# Main function
main() {
  log "Starting PowerShell installation process"
  check_existing_installation
  update_repos
  install_prerequisites
  get_os_version
  add_ms_repo
  update_repos
  install_powershell
  verify_installation
  log "Installation complete. Run 'pwsh' to start PowerShell."
  return 0
}

# Execute main function
main
