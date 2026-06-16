#!/usr/bin/env bash

confirm() {
  if [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi

  local prompt="${1:-Proceed?} [y/N] "
  local reply

  read -n 1 -r -p "$prompt" reply
  echo
  [[ "$reply" =~ ^[Yy]$ ]]
}
