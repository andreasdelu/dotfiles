#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

set_macos_defaults() {
  echo "Configuring macOS settings..."
  sudo -v
  # Set Dock autohide to false
  sudo defaults write com.apple.dock autohide -int 0
  # Set Dock tilesize to 56
  sudo defaults write com.apple.dock tilesize -int 56
  # Set the Dock tilesize largest size to 63
  sudo defaults write com.apple.dock largesize -int 63
  # Do not show recent applications in Dock
  sudo defaults write com.apple.dock show-recents -int 0
  # Enable click for trackpads
  sudo defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1
  # Kill Dock to apply changes
  sudo killall Dock

  echo "macOS defaults configured."
}

main() {
  if ! confirm "Do you want to configure macOS system defaults?"; then
    echo "Skipping macOS system defaults configuration."
    return
  fi

  set_macos_defaults
}

main "$@" 
