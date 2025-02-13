#!/usr/bin/env bash
set -e

./scripts/set_macos_defaults.sh
./scripts/install_homebrew.sh
./scripts/install_ohmyzsh.sh
./scripts/install_git.sh
./scripts/install_apps_and_packages.sh
./scripts/setup_dotfiles.sh

echo "Bootstrap setup complete!"