#!/usr/bin/env bash
# Stub all mutation surfaces, and execute only a temporary copy of bootstrap.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/home" "$scratch/bin"
cp -R "$REPO_DIR/scripts" "$REPO_DIR/config" "$REPO_DIR/bootstrap.sh" "$scratch/repo/"
rm -f "$scratch/repo/config/dotfiles/local.env"
export HOME="$scratch/home" TEST_OPTIONS="$scratch/options" TEST_SUDO="$scratch/sudo"
export PATH="$scratch/bin:/usr/bin:/bin"
unset DOTFILES_MACOS_DESKTOP DOTFILES_GHOSTTY_PANE_DIMMING DOTFILES_PI_OVERWATCH
cat > "$scratch/repo/scripts/checkbox_menu.sh" <<'STUB'
checkbox_menu() { printf '%s\n' "$@" > "$TEST_OPTIONS"; }
STUB
cat > "$scratch/bin/sudo" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_SUDO"
exit 99
STUB
chmod +x "$scratch/bin/sudo"
for platform in Linux Darwin; do
  printf '#!/bin/sh\nprintf "%s\\n"\n' "$platform" > "$scratch/bin/uname"
  chmod +x "$scratch/bin/uname"
  for flag in 0 1; do
    DOTFILES_MACOS_DESKTOP="$flag" bash "$scratch/repo/bootstrap.sh" > /dev/null
    if command -v ruby >/dev/null 2>&1; then
      DOTFILES_MACOS_DESKTOP="$flag" ruby - "$REPO_DIR/Brewfile" "$platform" <<'RUBY'
module OS
  def self.mac?; ARGV[1] == "Darwin"; end
end
$casks = []
def cask(name); $casks << name; end
def brew(name); end
load ARGV[0]
expected = OS.mac? && ENV["DOTFILES_MACOS_DESKTOP"] == "1"
abort "Incorrect cask filtering" unless (!$casks.empty?) == expected
RUBY
    else
      echo 'SKIP: Brewfile evaluation requires Ruby'
    fi
    if [[ "$platform:$flag" == Darwin:1 ]]; then
      grep -q '^macos|' "$TEST_OPTIONS"
    else
      ! grep -q '^macos|' "$TEST_OPTIONS"
    fi
    if [[ "$platform" == Linux ]]; then
      ! grep -q '^homebrew|\|^brewfile|' "$TEST_OPTIONS"
    fi
  done
done
# Direct entrypoint also requires opt-in, and assume-yes cannot authorize it.
DOTFILES_MACOS_DESKTOP=0 DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/set_macos_defaults.sh" <<< y > /dev/null
DOTFILES_MACOS_DESKTOP=1 DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/set_macos_defaults.sh" <<< n > /dev/null
[[ ! -e "$TEST_SUDO" ]]
printf 'PASS: simulated bootstrap platform/preferences, direct defaults opt-in and separate confirmation\n'
