#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/scripts/checkbox_menu.sh"

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

run_brew_bundle() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required before installing Brewfile packages."
    echo "Run this again and select Homebrew, or install Homebrew manually."
    return 1
  fi

  brew bundle install

  if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
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

selected_output="$(
  checkbox_menu "Set up your dotfiles" \
    "homebrew|Install Homebrew" \
    "brewfile|Install Brewfile packages and apps" \
    "ohmyzsh|Install oh-my-zsh" \
    "dotfiles|Link dotfiles from config/" \
    "github|Authenticate GitHub" \
    "macos|Configure macOS system defaults"
)"

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

is_selected homebrew && run_script_step "Install Homebrew" install_homebrew.sh
is_selected brewfile && run_named_step "Install Brewfile packages and apps" run_brew_bundle
is_selected ohmyzsh && run_script_step "Install oh-my-zsh" install_ohmyzsh.sh
is_selected dotfiles && run_script_step "Link dotfiles" setup_dotfiles.sh
is_selected github && run_script_step "Authenticate GitHub" authenticate_git.sh
is_selected macos && run_script_step "Configure macOS system defaults" set_macos_defaults.sh

printf '\n%b✨ Bootstrap setup complete!%b\n' "$GREEN$BOLD" "$RESET"
