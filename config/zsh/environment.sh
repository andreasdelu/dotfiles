# Discover installed tools before loading plugins and aliases.
path_prepend_if_missing() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  [[ ":$PATH:" == *":$dir:"* ]] && return 0
  export PATH="$dir:$PATH"
}

if [[ "$OSTYPE" == darwin* ]]; then
  for brew_bin in /opt/homebrew/bin /usr/local/bin; do
    [[ -x "$brew_bin/brew" ]] && path_prepend_if_missing "$brew_bin"
  done
  if (( $+commands[brew] )); then
    path_prepend_if_missing "$(brew --prefix)/opt/postgresql@17/bin"
  fi
fi
if [[ -z ${PNPM_HOME+x} ]]; then
  if [[ "$OSTYPE" == darwin* ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
  else
    export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
  fi
fi
for bin_dir in "$PNPM_HOME" "$HOME/.bun/bin" "$HOME/bin" "$HOME/.local/bin"; do
  path_prepend_if_missing "$bin_dir"
done
unset brew_bin bin_dir
