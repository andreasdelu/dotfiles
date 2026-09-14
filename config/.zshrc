# Preferences precede all shell/tool setup; child processes inherit the flags.
if [[ -r "$HOME/.config/dotfiles/env.sh" ]]; then
  source "$HOME/.config/dotfiles/env.sh"
  dotfiles_load_preferences "$HOME/.config/dotfiles/local.env"
fi

# Discover installed tools before loading plugins and aliases.
path_prepend_if_missing() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  [[ ":$PATH:" == *":$dir:"* ]] && return 0
  export PATH="$dir:$PATH"
}

for brew_bin in /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin; do
  [[ -x "$brew_bin/brew" ]] && path_prepend_if_missing "$brew_bin"
done
if (( $+commands[brew] )); then
  path_prepend_if_missing "$(brew --prefix)/opt/postgresql@17/bin"
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

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto

plugins=()
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  for plugin in git aliases fzf z timer zsh-autosuggestions; do
    if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$plugin" || -d "$ZSH/plugins/$plugin" ]]; then
      plugins+=("$plugin")
    fi
  done
  unset plugin
  source "$ZSH/oh-my-zsh.sh"
fi

# Hooks
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Aliases
alias zshconfig='nvim ~/.zshrc'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gclean='git reset --soft $(git merge-base HEAD main)'
alias md='make dev'
alias mt='make types'
alias td='task dev'
alias tdg='task dev:enable-goodjob'
alias tgqd='task graphql:dump'
alias gglm='git pull origin main'
(( $+commands[eza] )) && alias ls='eza --icons=always -a'
alias ts='echo -e "\n\033[1;35m--- 🕒 SYSTEM TIMESTAMPS ---\033[0m"; \
echo -e "\033[1;32mLocal     :\033[0m \033[36m$(date "+%A, %B %d, %Y %H:%M:%S")\033[0m"; \
echo -e "\033[1;32mISO-8601  :\033[0m \033[33m$(date "+%Y-%m-%dT%H:%M:%S%z")\033[0m"; \
echo -e "\033[1;32mUnix Epoch:\033[0m \033[1;37m$(date +%s)\033[0m"; \
echo -e "\033[1;32mUTC/Zulu  :\033[0m \033[34m$(date -u "+%H:%M:%S UTC")\033[0m"; \
echo -e "\033[1;32mFilename  :\033[0m \033[90m$(date "+%Y%m%d%H%M%S")\033[0m"; \
echo -e "\033[1;35m----------------------------\033[0m\n"'
if [[ -x "$HOME/Documents/pax/bin/pax" ]]; then
  alias pax='~/Documents/pax/bin/pax --cwd "$PWD"'
  alias paxc='~/Documents/pax/bin/pax --cwd "$PWD" --continue'
fi
[[ -x "$HOME/pip/bin/pip" ]] && alias pip='~/pip/bin/pip'
# Clear the old alias on reload; Overwatch is optional, not a TWM prerequisite.
unalias twm 2>/dev/null || true
if [[ -x "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm" ]]; then
  alias twm='TWM_OVERWATCH_ENABLE=false ~/.tmux/plugins/tmux-worktree-manager/dist/twm'
  if [[ "${DOTFILES_PI_OVERWATCH:-0}" == 1 && -d "$HOME/.pi/overwatch/agents" ]]; then
    alias twm='TWM_OVERWATCH_ENABLE=true ~/.tmux/plugins/tmux-worktree-manager/dist/twm'
  fi
fi

# Functions
gfixup() {
  if [[ -z "$1" ]]; then
    echo "Usage: gfixup <commit-sha>" >&2
    return 1
  fi

  git commit --fixup "$1"
}

grbia() {
  if [[ -z "$1" ]]; then
    echo "Usage: grbia <commit-sha>" >&2
    return 1
  fi

  git rebase -i --autosquash "$1"~
}

updatedotfiles() {
  local dotfiles_dir="$HOME/.dotfiles"
  git -C "$dotfiles_dir" pull origin main && "$dotfiles_dir/bootstrap.sh"
}

# A minimal installation without optional tools should still start successfully.
true
