#!/usr/bin/env bash
set -e

install_apps_and_packages() {
  # Check if mas is installed
  if ! command -v mas &> /dev/null; then
    echo "Installing mas (Mac App Store CLI)..."
    brew install mas
    read -p "Please make sure you are signed into the Mac App Store - press any key to continue..."
  fi

  # Check if user is signed into Mac App Store
  if ! mas account &> /dev/null; then
    echo "Please sign into the Mac App Store first and run this script again"
    exit 1
  fi

  # Install applications from Mac App Store
  echo "Installing applications from Mac App Store..."
  mas install 1480068668 # Messenger
  mas install 472226235 # Lanscan

  echo "Installing applications and packages via Homebrew Bundle..."
  brew bundle
}

install_apps_and_packages