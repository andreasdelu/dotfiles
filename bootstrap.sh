#!/usr/bin/env bash
set -euo pipefail

run_step() {
  local script="$1"
  "./scripts/$script"
  echo
}

run_step set_macos_defaults.sh
run_step install_homebrew.sh
run_step install_ohmyzsh.sh
run_step authenticate_git.sh
run_step setup_dotfiles.sh

if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo ""
echo "--------------------------------"
echo "Installing brew packages..."
echo "--------------------------------"
echo ""
brew bundle install

echo "Bootstrap setup complete!"
