#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

main() {
  if ! confirm "Do you want to authenticate GitHub?"; then
    echo "Skipping GitHub authentication."
    return
  fi

  gh auth login
  echo "Signed in to GitHub!"
}

main "$@" 
