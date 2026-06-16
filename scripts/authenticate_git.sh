#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

main() {
  if ! confirm "Do you want to authenticate GitHub?"; then
    echo "Skipping GitHub authentication."
    return
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI not found. Install the Brewfile packages first, then run this step again."
    return 1
  fi

  if gh auth status --hostname github.com --active >/dev/null 2>&1; then
    echo "Already signed in to GitHub."
    return
  fi

  echo "GitHub authentication not configured for github.com. Starting login..."
  gh auth login --hostname github.com
  echo "Signed in to GitHub!"
}

main "$@" 
