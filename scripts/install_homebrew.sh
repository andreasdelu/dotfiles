#!/usr/bin/env bash
set -e

confirm() {
  local prompt="${1:-Proceed?} [y/N] "
  read -n 1 -r -p "$prompt" reply
  echo
  [[ "$reply" =~ ^[Yy]$ ]]
}

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