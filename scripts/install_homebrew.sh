#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed."
  fi
}

main() {
  if ! confirm "Do you want to install Homebrew?"; then
    echo "Skipping Homebrew installation."
    return
  fi

  install_homebrew
}

main "$@" 
