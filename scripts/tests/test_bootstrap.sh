#!/usr/bin/env bash
# Stub all mutation surfaces, and execute only a temporary copy of bootstrap.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/home" "$scratch/bin"
cp -R "$REPO_DIR/scripts" "$REPO_DIR/config" "$REPO_DIR/maps" "$REPO_DIR/bootstrap.sh" "$scratch/repo/"
rm -f "$scratch/repo/config/dotfiles/local.env"
export HOME="$scratch/home" TEST_OPTIONS="$scratch/options" TEST_SUDO="$scratch/sudo" TEST_GIT="$scratch/git"
export PATH="$scratch/bin:/usr/bin:/bin"
unset DOTFILES_GHOSTTY_PANE_DIMMING
cat > "$scratch/repo/scripts/checkbox_menu.sh" <<'STUB'
checkbox_menu() {
  printf '%s\n' "$@" > "$TEST_OPTIONS"
  [[ -z "${TEST_SELECTION:-}" ]] || printf '%s\n' "$TEST_SELECTION"
}
STUB
cat > "$scratch/bin/sudo" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_SUDO"
exit 99
STUB
chmod +x "$scratch/bin/sudo"
printf '#!/bin/sh\nexit 99\n' > "$scratch/bin/apt-get"
printf '#!/bin/sh\nexit 99\n' > "$scratch/bin/brew"
chmod +x "$scratch/bin/apt-get" "$scratch/bin/brew"
for platform in Linux Darwin; do
  printf '#!/bin/sh\nprintf "%s\\n"\n' "$platform" > "$scratch/bin/uname"
  chmod +x "$scratch/bin/uname"
  bash "$scratch/repo/bootstrap.sh" > /dev/null
  if command -v ruby >/dev/null 2>&1; then
    status=0
    ruby - "$REPO_DIR/Brewfile" "$platform" > "$scratch/brew-$platform" 2>&1 <<'RUBY' || status=$?
module OS
  def self.mac?; ARGV[1] == "Darwin"; end
end
$casks = []
def cask(name); $casks << name; end
def brew(name); end
load ARGV[0]
abort "Expected macOS casks" if $casks.empty?
RUBY
    if [[ "$platform" == Darwin ]]; then [[ "$status" == 0 ]]; else [[ "$status" != 0 ]]; fi
  else
    echo 'SKIP: Brewfile evaluation requires Ruby'
  fi
  if [[ "$platform" == Darwin ]]; then
    grep -q '^macos|\|^homebrew|\|^brewfile|' "$TEST_OPTIONS"
    ! grep -q '^linux-packages|' "$TEST_OPTIONS"
  else
    grep -q '^linux-packages|' "$TEST_OPTIONS"
    ! grep -q '^homebrew|\|^brewfile|\|^macos|' "$TEST_OPTIONS"
  fi
done
# The macOS installer owns Brewfile execution even when called outside the repo.
export TEST_BREW="$scratch/brew-called"
cat > "$scratch/bin/brew" <<'STUB'
#!/bin/sh
printf '%s :: %s\n' "$PWD" "$*" >> "$TEST_BREW"
STUB
chmod +x "$scratch/bin/brew"
(cd "$scratch" && bash "$scratch/repo/scripts/install/macos/brewfile.sh")
grep -Fq "$scratch/repo :: bundle install" "$TEST_BREW"
TEST_SELECTION=brewfile DOTFILES_ASSUME_YES=1 bash "$scratch/repo/bootstrap.sh" > /dev/null
[[ $(wc -l < "$TEST_BREW") -eq 2 ]]
TEST_SELECTION=homebrew DOTFILES_ASSUME_YES=1 bash "$scratch/repo/bootstrap.sh" > "$scratch/homebrew-step"
grep -q 'Homebrew is already installed' "$scratch/homebrew-step"
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/bin/uname"
if bash "$scratch/repo/scripts/install/macos/brewfile.sh" > "$scratch/linux-brewfile" 2>&1; then
  echo 'Brewfile installer unexpectedly ran on Linux' >&2; exit 1
fi
[[ $(wc -l < "$TEST_BREW") -eq 2 ]]
# On a fresh Linux machine, apt can supply zsh for the selected Oh My Zsh step.
mkdir -p "$scratch/no-zsh-bin"
for command_name in dirname date env sh bash; do
  ln -s "$(command -v "$command_name")" "$scratch/no-zsh-bin/$command_name"
done
cp "$scratch/bin/apt-get" "$scratch/no-zsh-bin/apt-get"
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/no-zsh-bin/uname"
chmod +x "$scratch/no-zsh-bin/uname"
TEST_ZSH_PATH="$scratch/no-zsh-bin/zsh"
export TEST_ZSH_PATH
PATH="$scratch/no-zsh-bin" /bin/bash "$scratch/repo/bootstrap.sh" > /dev/null
grep -q '^ohmyzsh|' "$TEST_OPTIONS"
mv "$scratch/no-zsh-bin/apt-get" "$scratch/apt-get-stub"
PATH="$scratch/no-zsh-bin" /bin/bash "$scratch/repo/bootstrap.sh" > /dev/null 2> "$scratch/unsupported-linux"
! grep -q '^ohmyzsh|\|^linux-packages|' "$TEST_OPTIONS"
grep -q 'No supported Linux package manager' "$scratch/unsupported-linux"
mv "$scratch/apt-get-stub" "$scratch/no-zsh-bin/apt-get"
if TEST_SELECTION=ohmyzsh DOTFILES_ASSUME_YES=1 PATH="$scratch/no-zsh-bin" /bin/bash "$scratch/repo/bootstrap.sh" > "$scratch/no-zsh-output" 2>&1; then
  echo 'Oh My Zsh ran without zsh or the apt step' >&2; exit 1
fi
grep -q 'Install zsh first' "$scratch/no-zsh-output"
cat > "$scratch/repo/scripts/install/linux/apt.sh" <<'STUB'
#!/bin/sh
printf '#!/bin/sh\nexit 0\n' > "$TEST_ZSH_PATH"
/bin/chmod +x "$TEST_ZSH_PATH"
STUB
cat > "$scratch/no-zsh-bin/curl" <<'STUB'
#!/bin/sh
test -x "$TEST_ZSH_PATH" || exit 99
printf ':'
STUB
chmod +x "$scratch/repo/scripts/install/linux/apt.sh" "$scratch/no-zsh-bin/curl"
TEST_SELECTION=$'linux-packages\nohmyzsh' DOTFILES_ASSUME_YES=1 PATH="$scratch/no-zsh-bin" /bin/bash "$scratch/repo/bootstrap.sh" > "$scratch/first-linux-run"
[[ -x "$TEST_ZSH_PATH" ]]
grep -q 'Installing oh-my-zsh' "$scratch/first-linux-run"
# Linking must install TPM even when neither Brewfile nor Homebrew was selected.
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$scratch/bin/uname"
printf '#!/bin/sh\nexit 0\n' > "$scratch/bin/tmux"
cat > "$scratch/bin/git" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_GIT"
STUB
chmod +x "$scratch/bin/uname" "$scratch/bin/tmux" "$scratch/bin/git"
if [[ -d "$scratch/repo/config/tmux/plugins" ]]; then
  mv "$scratch/repo/config/tmux/plugins" "$scratch/installed-plugins"
fi
TEST_SELECTION=dotfiles DOTFILES_ASSUME_YES=1 bash "$scratch/repo/bootstrap.sh" > /dev/null
[[ -d "$HOME/.tmux/plugins" ]]
grep -Fq "clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm" "$TEST_GIT"
# Direct macOS defaults still need consent even under assume-yes.
printf '#!/bin/sh\nprintf "Darwin\\n"\n' > "$scratch/bin/uname"
[[ ! -e "$TEST_SUDO" ]]
DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/set_macos_defaults.sh" <<< n > /dev/null
[[ ! -e "$TEST_SUDO" ]]
export TEST_DEFAULTS="$scratch/defaults" TEST_KILLALL="$scratch/killall"
cat > "$scratch/bin/defaults" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_DEFAULTS"
STUB
cat > "$scratch/bin/killall" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_KILLALL"
STUB
chmod +x "$scratch/bin/defaults" "$scratch/bin/killall"
DOTFILES_ASSUME_YES=1 bash "$scratch/repo/scripts/set_macos_defaults.sh" <<< y > /dev/null
[[ ! -e "$TEST_SUDO" ]]
[[ $(wc -l < "$TEST_DEFAULTS") -eq 5 ]]
grep -q '^write com.apple.dock autohide -int 0$' "$TEST_DEFAULTS"
grep -qx 'Dock' "$TEST_KILLALL"
printf 'PASS: simulated OS package steps, macOS casks/consent, TPM without Brewfile\n'
