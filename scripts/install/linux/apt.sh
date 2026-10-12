#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Linux ]] || ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer requires Linux with apt-get." >&2
  exit 1
fi

packages=(git zsh tmux fzf ripgrep curl ca-certificates python3 build-essential)
if (( EUID == 0 )); then
  apt-get update
  apt-get install -y "${packages[@]}"
else
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
fi

"$(dirname "${BASH_SOURCE[0]}")/editor.sh"
