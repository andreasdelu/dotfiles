#!/usr/bin/env bash
set -e

confirm() {
  local prompt="${1:-Proceed?} [y/N] "
  read -n 1 -r -p "$prompt" reply
  echo
  [[ "$reply" =~ ^[Yy]$ ]]
}

main() {
  if ! confirm "Do you want to authenticate GitHub?"; then
    echo "Skipping GitHub authentication."
    return
  fi

  gh auth login
  echo "Signed in to GitHub!"
}

main "$@" 