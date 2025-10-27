#!/usr/bin/env bash
set -e

confirm() {
  local prompt="${1:-Proceed?} [y/N] "
  read -n 1 -r -p "$prompt" reply
  echo
  [[ "$reply" =~ ^[Yy]$ ]]
}

install_ohmyzsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "oh-my-zsh is already installed."
  fi
}

main() {
  if ! confirm "Do you want to install oh-my-zsh?"; then
    echo "Skipping oh-my-zsh installation."
    return
  fi

  install_ohmyzsh
}

main "$@" 