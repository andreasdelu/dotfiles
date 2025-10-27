# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto      # update automatically without asking

plugins=(git aliases fzf z timer zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

if [ -f "$HOME/.dotfiles/.env.local" ]; then
    . "$HOME/.dotfiles/.env.local"
fi

alias zshconfig="nvim ~/.zshrc"
alias gtmp='git checkout -b TEMP-$(git rev-parse --abbrev-ref HEAD)'
alias gclean='git reset --soft $(git merge-base HEAD main)'
alias md='make dev'
alias mt='make types'
alias td='task dev'
alias tdg='task dev:enable-goodjob'
alias tgqd='task graphql:dump'
alias gglm='git pull origin main'
alias ls='eza --icons=always -a'

# Functions
gfixup() {
  if [ -z "$1" ]; then
    echo "Usage: gfixup <commit-sha>" >&2
    return 1
  fi
  git commit --fixup "$1"
}

grbia() {
  if [ -z "$1" ]; then
    echo "Usage: grbia <commit-sha>" >&2
    return 1
  fi
  git rebase -i --autosquash "$1"~
}

updatedotfiles() {
  local dotfiles_dir="$HOME/.dotfiles"
  git -C "$dotfiles_dir" pull origin main && "$dotfiles_dir/bootstrap.sh"
}

export PATH="/Users/andreasdeleuran/.bun/bin:$PATH"

export GOOGLE_CLOUD_PROJECT="andreas-landfolk-api-testing"

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/andreasdeleuran/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
