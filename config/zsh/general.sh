# Aliases
alias zshconfig='nvim ~/.zshrc'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gclean='git reset --soft $(git merge-base HEAD main)'
alias gglm='git pull origin main'
(( $+commands[eza] )) && alias ls='eza --icons=always -a'
alias ts='echo -e "\n\033[1;35m--- 🕒 SYSTEM TIMESTAMPS ---\033[0m"; \
echo -e "\033[1;32mLocal     :\033[0m \033[36m$(date "+%A, %B %d, %Y %H:%M:%S")\033[0m"; \
echo -e "\033[1;32mISO-8601  :\033[0m \033[33m$(date "+%Y-%m-%dT%H:%M:%S%z")\033[0m"; \
echo -e "\033[1;32mUnix Epoch:\033[0m \033[1;37m$(date +%s)\033[0m"; \
echo -e "\033[1;32mUTC/Zulu  :\033[0m \033[34m$(date -u "+%H:%M:%S UTC")\033[0m"; \
echo -e "\033[1;32mFilename  :\033[0m \033[90m$(date "+%Y%m%d%H%M%S")\033[0m"; \
echo -e "\033[1;35m----------------------------\033[0m\n"'
[[ -x "$HOME/pip/bin/pip" ]] && alias pip='~/pip/bin/pip'
unalias twm 2>/dev/null || true
if [[ -x "$HOME/.tmux/plugins/tmux-worktree-manager/dist/twm" ]]; then
  alias twm='~/.tmux/plugins/tmux-worktree-manager/dist/twm'
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

tmuxhere() {
  tmux if-shell -F -t "$TMUX_PANE" '1' 'attach-session -c "#{pane_current_path}"'
}
