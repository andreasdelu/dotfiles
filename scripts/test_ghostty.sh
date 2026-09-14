#!/usr/bin/env bash
# validate-config takes an explicit file; show-config on macOS can read the
# account's Library config despite HOME, so it is not used for isolation.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v ghostty >/dev/null || { echo 'SKIP: Ghostty CLI not installed'; exit 0; }
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch"
mkdir -p "$HOME/.config/ghostty/shaders"
cp "$REPO_DIR/config/.ghostty" "$HOME/base.conf"
ghostty +validate-config --config-file="$HOME/base.conf"
cp "$REPO_DIR/config/ghostty/pane-dimming.conf" "$HOME/.config/ghostty/"
cp "$REPO_DIR/config/ghostty/shaders/tmux-pane-dimmer.glsl" "$HOME/.config/ghostty/shaders/"
ghostty +validate-config --config-file="$HOME/base.conf"
# Prove the optional tilde include is actually traversed, not silently skipped.
printf '\ndotfiles-invalid-test-key = true\n' >> "$HOME/.config/ghostty/pane-dimming.conf"
if ghostty +validate-config --config-file="$HOME/base.conf" > "$scratch/invalid" 2>&1; then
  echo 'FAIL: Ghostty did not reject the deliberately invalid included file' >&2
  exit 1
fi
grep -q 'dotfiles-invalid-test-key' "$scratch/invalid"
printf 'PASS: native Ghostty optional include absent/present and tilde-path traversal\n'
