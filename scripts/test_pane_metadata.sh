#!/usr/bin/env bash
# Stub tmux's query surface to test palette/popup side effects without a terminal.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME/.tmux/bin" "$scratch/bin"
cp "$REPO_DIR/config/.tmux/bin/"* "$HOME/.tmux/bin/"
export TEST_CALLS="$scratch/calls" TEST_TTY="$scratch/tty" TEST_FEATURE=off
: > "$TEST_TTY"
cat > "$scratch/bin/tmux" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  show-option) printf '%s\n' "$TEST_FEATURE" ;;
  list-clients) printf 'test-client|%s\n' "$TEST_TTY" ;;
  display-popup) printf 'popup\n' >> "$TEST_CALLS" ;;
esac
STUB
cat > "$HOME/.tmux/bin/emit-pane-metadata" <<'STUB'
#!/usr/bin/env bash
printf 'metadata %s\n' "$*" >> "$TEST_CALLS"
STUB
printf '#!/bin/sh\nexit 0\n' > "$scratch/bin/fzf"
chmod +x "$scratch/bin/"* "$HOME/.tmux/bin/emit-pane-metadata"
export PATH="$scratch/bin:$PATH"
"$HOME/.tmux/bin/display-popup" sessions test-client %1
! grep -q metadata "$TEST_CALLS"
TEST_FEATURE=on "$HOME/.tmux/bin/display-popup" sessions test-client %1
[[ "$(grep -c metadata "$TEST_CALLS")" == 2 ]]
# Off suppresses normal emissions; explicit verified cleanup still works after
# detach/off, and never writes to other terminal types.
"$HOME/.tmux/bin/emit-pane-overlay" "$TEST_TTY" xterm-ghostty 80 24 8 16 23 false bottom 0 0 40 23
[[ ! -s "$TEST_TTY" ]]
"$HOME/.tmux/bin/emit-pane-overlay" --clear "$TEST_TTY" xterm
[[ ! -s "$TEST_TTY" ]]
"$HOME/.tmux/bin/emit-pane-overlay" --clear "$TEST_TTY" xterm-ghostty
[[ -s "$TEST_TTY" ]]
grep -q '104;160;161;162;163;164;165' "$TEST_TTY"
printf 'PASS: popup metadata gated, disabled emitter inert, detached cleanup terminal-gated\n'
