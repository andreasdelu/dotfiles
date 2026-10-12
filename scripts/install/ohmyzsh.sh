#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/../common.sh"

install_ohmyzsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "oh-my-zsh is already installed."
  fi
}

main() {
  if ! command -v zsh >/dev/null 2>&1; then
    echo "Install zsh first (select the Linux packages step, if available)." >&2
    return 1
  fi
  if ! confirm "Do you want to install oh-my-zsh?"; then
    echo "Skipping oh-my-zsh installation."
    return
  fi

  install_ohmyzsh
}

main "$@" 
