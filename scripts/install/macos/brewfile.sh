#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "Brewfile setup is macOS-only." >&2; exit 1; }

# Homebrew may have been installed in an earlier bootstrap child process.
if ! command -v brew >/dev/null 2>&1; then
  for bin_dir in /opt/homebrew/bin /usr/local/bin; do
    if [[ -x "$bin_dir/brew" ]]; then
      export PATH="$bin_dir:$PATH"
      break
    fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required before installing Brewfile packages." >&2
  echo "Run this again and select Homebrew, or install Homebrew manually." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_dir"
brew bundle install
