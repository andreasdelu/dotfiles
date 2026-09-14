# shellcheck shell=sh
# Shared by bash bootstrap helpers and zsh, before other setup.
# This is a deliberately small data format, not an executable shell config.
dotfiles_load_preferences() {
  local file="$1" line
  if [ -f "$file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*) continue ;;
        DOTFILES_MACOS_DESKTOP=[01])
          : "${DOTFILES_MACOS_DESKTOP=${line#*=}}" ;;
        DOTFILES_GHOSTTY_PANE_DIMMING=[01])
          : "${DOTFILES_GHOSTTY_PANE_DIMMING=${line#*=}}" ;;
        DOTFILES_PI_OVERWATCH=[01])
          : "${DOTFILES_PI_OVERWATCH=${line#*=}}" ;;
        *) printf 'Invalid dotfiles preference in %s: %s\n' "$file" "$line" >&2; return 1 ;;
      esac
    done < "$file"
  fi
  # Set-but-empty and explicit 0 values must win over file defaults, too.
  export DOTFILES_MACOS_DESKTOP="${DOTFILES_MACOS_DESKTOP-0}"
  export DOTFILES_GHOSTTY_PANE_DIMMING="${DOTFILES_GHOSTTY_PANE_DIMMING-0}"
  export DOTFILES_PI_OVERWATCH="${DOTFILES_PI_OVERWATCH-0}"
}
