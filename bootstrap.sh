#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"
. "$REPO_DIR/config/dotfiles/env.sh"
dotfiles_load_preferences "$REPO_DIR/config/dotfiles/local.env"
. "$REPO_DIR/scripts/checkbox_menu.sh"

RESET="" BOLD="" DIM="" CYAN="" GREEN="" RED="" YELLOW="" GRAY=""
if [[ -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  CYAN=$'\033[36m'
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  GRAY=$'\033[90m'
fi

step_header() {
  local title="$1"
  printf '\n%b┌─ %s%b\n' "$BOLD$CYAN" "$title" "$RESET"
  printf '%b│%b\n' "$GRAY" "$RESET"
}

step_footer() {
  local status="$1"
  local title="$2"
  local elapsed="$3"

  if [[ "$status" == "success" ]]; then
    printf '%b│%b\n' "$GRAY" "$RESET"
    printf '%b└─ ✓ %s%b %b(%ss)%b\n' "$GREEN" "$title" "$RESET" "$DIM" "$elapsed" "$RESET"
  else
    printf '%b│%b\n' "$GRAY" "$RESET"
    printf '%b└─ ✕ %s failed%b %b(%ss)%b\n' "$RED" "$title" "$RESET" "$DIM" "$elapsed" "$RESET"
  fi
}

run_named_step() {
  local title="$1"
  shift

  local start end elapsed status
  start="$(date +%s)"
  step_header "$title"

  if "$@"; then
    end="$(date +%s)"
    elapsed=$((end - start))
    step_footer success "$title" "$elapsed"
  else
    status=$?
    end="$(date +%s)"
    elapsed=$((end - start))
    step_footer failure "$title" "$elapsed"
    return "$status"
  fi
}

run_script_step() {
  local title="$1"
  local script="$2"
  run_named_step "$title" env DOTFILES_ASSUME_YES=1 "./scripts/$script"
}

install_tpm() {
  if ! command -v tmux >/dev/null 2>&1; then
    echo "Skipping TPM: install tmux first."
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "Skipping TPM: install git first."
    return 0
  fi
  if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

is_selected() {
  local needle="$1"
  local selected
  for selected in "${SELECTED_STEPS[@]}"; do
    [[ "$selected" == "$needle" ]] && return 0
  done
  return 1
}

steps=()
linux_packages_available=0
case "$(uname -s)" in
  Darwin)
    steps+=("homebrew|Install Homebrew" "brewfile|Install Brewfile packages and apps")
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      linux_packages_available=1
      steps+=("linux-packages|Install apt packages and latest stable editor")
    else
      echo "No supported Linux package manager found (apt-get). Install dependencies manually; linking remains available." >&2
    fi
    ;;
esac
if command -v zsh >/dev/null 2>&1 || [[ "$linux_packages_available" == 1 ]]; then
  steps+=("ohmyzsh|Install oh-my-zsh")
fi
steps+=("dotfiles|Link dotfiles and install TPM")
if command -v gh >/dev/null 2>&1 || [[ "$(uname -s)" == Darwin ]]; then
  steps+=("github|Authenticate GitHub")
fi
if [[ "$(uname -s)" == Darwin ]]; then
  steps+=("macos|Configure macOS system defaults")
fi
selected_output="$(checkbox_menu "Set up your dotfiles" "${steps[@]}")"

SELECTED_STEPS=()
if [[ -n "$selected_output" ]]; then
  while IFS= read -r selected_step; do
    [[ -n "$selected_step" ]] && SELECTED_STEPS+=("$selected_step")
  done <<< "$selected_output"
fi

if [[ ${#SELECTED_STEPS[@]} -eq 0 ]]; then
  echo "No bootstrap steps selected. Nothing to do."
  exit 0
fi

printf '\n%bRunning %s selected bootstrap step(s)...%b\n' "$BOLD" "${#SELECTED_STEPS[@]}" "$RESET"

is_selected linux-packages && run_script_step "Install apt packages and editor" install/linux/apt.sh
is_selected homebrew && run_script_step "Install Homebrew" install/macos/homebrew.sh
is_selected brewfile && run_script_step "Install Brewfile packages and apps" install/macos/brewfile.sh
is_selected ohmyzsh && run_script_step "Install oh-my-zsh" install/ohmyzsh.sh
is_selected dotfiles && run_script_step "Link dotfiles" setup_dotfiles.sh
# Link first: otherwise a fresh ~/.tmux directory (including TPM) is backed up.
is_selected dotfiles && run_named_step "Install tmux plugin manager" install_tpm
is_selected github && run_script_step "Authenticate GitHub" authenticate_git.sh
# Never let the general assume-yes path authorize system preference changes.
is_selected macos && run_named_step "Configure macOS system defaults" env DOTFILES_ASSUME_YES=0 ./scripts/set_macos_defaults.sh

printf '\n%b✨ Bootstrap setup complete!%b\n' "$GREEN$BOLD" "$RESET"
if [[ "$(uname -s)" == Darwin ]]; then
  echo "Vorssaint: import exports/vorssaint-settings.plist in Settings → Advanced → Import settings."
fi
