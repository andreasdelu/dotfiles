#!/usr/bin/env bash
set -e

install_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "Git not found. Installing Git..."
    brew install git
  else
    echo "Git is already installed."
  fi
}

install_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) not found. Installing GitHub CLI..."
    brew install gh
  else
    echo "GitHub CLI (gh) is already installed."
  fi
}

configure_git() {
  # Prompt for github login
  read -p "Do you want to sign in to GitHub? (y/n): " github_login
  if [ "$github_login" = "y" ]; then
    gh auth login
    echo "Signed in to GitHub!"
  else
    echo "Skipping GitHub login."
  fi
}

install_git
install_gh
configure_git 