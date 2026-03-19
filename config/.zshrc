# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode auto      # update automatically without asking

plugins=(git aliases fzf z timer zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# direnv - mostly used for Nix
eval "$(direnv hook zsh)"

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
alias ts='echo -e "\n\033[1;35m--- 🕒 SYSTEM TIMESTAMPS ---\033[0m"; \
echo -e "\033[1;32mLocal     :\033[0m \033[36m$(date "+%A, %B %d, %Y %H:%M:%S")\033[0m"; \
echo -e "\033[1;32mISO-8601  :\033[0m \033[33m$(date "+%Y-%m-%dT%H:%M:%S%z")\033[0m"; \
echo -e "\033[1;32mUnix Epoch:\033[0m \033[1;37m$(date +%s)\033[0m"; \
echo -e "\033[1;32mUTC/Zulu  :\033[0m \033[34m$(date -u "+%H:%M:%S UTC")\033[0m"; \
echo -e "\033[1;32mFilename  :\033[0m \033[90m$(date "+%Y%m%d%H%M%S")\033[0m"; \
echo -e "\033[1;35m----------------------------\033[0m\n"'


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

export PATH="$HOME/.local/bin:$PATH"
