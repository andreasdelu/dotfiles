#!/usr/bin/env bash
set -e

# Get the directory where this script is located and reference dotfiles directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$( cd "$SCRIPT_DIR/../dotfiles" && pwd )"

symlink_zshrc() {
  ZSHRC="$HOME/.zshrc"
  if [ -e "$ZSHRC" ] || [ -L "$ZSHRC" ]; then
    echo ".zshrc already exists. Backing it up to .zshrc.backup"
    mv "$ZSHRC" "$HOME/.zshrc.backup"
  fi
  ln -s "$DOTFILES_DIR/.zshrc" "$ZSHRC"
  echo "Symlinked .zshrc from dotfiles."
}

symlink_github_config() {
  GITHUB_CONFIG="$HOME/.gitconfig"
  if [ -e "$GITHUB_CONFIG" ] || [ -L "$GITHUB_CONFIG" ]; then
    echo "GitHub config already exists. Backing it up to .gitconfig.backup"
    mv "$GITHUB_CONFIG" "$HOME/.gitconfig.backup"
  fi
  ln -s "$DOTFILES_DIR/.gitconfig" "$GITHUB_CONFIG"
  echo "Symlinked GitHub config from dotfiles."
}

symlink_aliases() {
  ALIASES="$HOME/.oh-my-zsh/custom/aliases.zsh"
  if [ -e "$ALIASES" ] || [ -L "$ALIASES" ]; then
    echo "Aliases already exists. Backing it up to aliases.backup"
    mv "$ALIASES" "$HOME/aliases.backup"
  fi
  ln -s "$DOTFILES_DIR/.aliases" "$ALIASES"
  echo "Symlinked aliases from dotfiles."
}

symlink_ghostty_config() {
  GHOSTTY_CONFIG="$HOME/Library/Application\ Support/com.mitchellh.ghostty/config"
  if [ -e "$GHOSTTY_CONFIG" ] || [ -L "$GHOSTTY_CONFIG" ]; then
    echo "Ghostty config already exists. Backing it up to ghostty.backup"
    mv "$GHOSTTY_CONFIG" "$HOME/ghostty.backup"
  fi
  ln -s "$DOTFILES_DIR/.ghostty" "$GHOSTTY_CONFIG"
  echo "Symlinked ghostty config from dotfiles."
}

symlink_zshrc
symlink_github_config 
symlink_aliases
symlink_ghostty_config