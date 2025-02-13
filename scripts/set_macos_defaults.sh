#!/usr/bin/env bash
set -e

set_macos_defaults() {
  echo "Configuring macOS settings..."
  read -p "Enter sudo password: " -s SUDO_PASSWORD
  # Set Dock autohide to false
  echo "$SUDO_PASSWORD" | sudo -S defaults write com.apple.dock autohide -int 0
  # Set Dock tilesize to 56
  echo "$SUDO_PASSWORD" | sudo -S defaults write com.apple.dock tilesize -int 56
  # Set the Dock tilesize largest size to 63
  echo "$SUDO_PASSWORD" | sudo -S defaults write com.apple.dock largesize -int 63
  # Do not show recent applications in Dock
  echo "$SUDO_PASSWORD" | sudo -S defaults write com.apple.dock show-recents -int 0
  # Enable click for trackpads
  echo "$SUDO_PASSWORD" | sudo -S defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1
  # Kill Dock to apply changes
  echo "$SUDO_PASSWORD" | sudo -S killall Dock

  echo "macOS defaults configured."
}

set_macos_defaults 