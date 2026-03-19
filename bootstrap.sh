#!/usr/bin/env bash
set -e

# Make all the scripts executable
chmod +x scripts/*.sh

./scripts/set_macos_defaults.sh
echo ""
./scripts/install_homebrew.sh
echo ""
./scripts/install_ohmyzsh.sh
echo ""
./scripts/authenticate_git.sh
echo ""
./scripts/setup_dotfiles.sh
echo ""

echo ""
echo "--------------------------------"
echo "Installing brew packages..."
echo "--------------------------------"
echo ""
# install brew packages
brew bundle install

echo "Bootstrap setup complete!"
