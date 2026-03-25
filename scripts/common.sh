#!/usr/bin/env bash

confirm() {
  local prompt="${1:-Proceed?} [y/N] "
  local reply

  read -n 1 -r -p "$prompt" reply
  echo
  [[ "$reply" =~ ^[Yy]$ ]]
}
