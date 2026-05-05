# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto

plugins=(git aliases fzf z timer zsh-autosuggestions)

source "$ZSH/oh-my-zsh.sh"

# Hooks
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Aliases
alias zshconfig='nvim ~/.zshrc'
alias gtmp='git checkout -b TEMP-$(git rev-parse --abbrev-ref HEAD)'
alias gclean='git reset --soft $(git merge-base HEAD main)'
alias md='make dev'
alias mt='make types'
alias td='task dev'
alias tdg='task dev:enable-goodjob'
alias tgqd='task graphql:dump'
alias gglm='git pull origin main'
alias ls='eza --icons=always -a'
alias ts='echo -e "\n\033[1;35m--- 🕒 SYSTEM TIMESTAMPS ---\033[0m"; \
echo -e "\033[1;32mLocal     :\033[0m \033[36m$(date "+%A, %B %d, %Y %H:%M:%S")\033[0m"; \
echo -e "\033[1;32mISO-8601  :\033[0m \033[33m$(date "+%Y-%m-%dT%H:%M:%S%z")\033[0m"; \
echo -e "\033[1;32mUnix Epoch:\033[0m \033[1;37m$(date +%s)\033[0m"; \
echo -e "\033[1;32mUTC/Zulu  :\033[0m \033[34m$(date -u "+%H:%M:%S UTC")\033[0m"; \
echo -e "\033[1;32mFilename  :\033[0m \033[90m$(date "+%Y%m%d%H%M%S")\033[0m"; \
echo -e "\033[1;35m----------------------------\033[0m\n"'
alias pax='~/Documents/pax/bin/pax --cwd "$PWD"'
alias pip='~/pip/bin/pip'

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

# PATH
path_prepend_if_missing() {
  local dir="$1"
  [[ -z "$dir" ]] && return 0
  [[ ":$PATH:" == *":$dir:"* ]] && return 0
  export PATH="$dir:$PATH"
}

export PNPM_HOME="$HOME/Library/pnpm"

path_prepend_if_missing "$HOME/.local/bin"
path_prepend_if_missing "$PNPM_HOME"
path_prepend_if_missing "/opt/homebrew/opt/postgresql@17/bin"
path_prepend_if_missing "/opt/homebrew/bin/bun"
path_prepend_if_missing "$HOME/bin"
