# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto

plugins=()
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  for plugin in git aliases fzf zoxide timer zsh-autosuggestions; do
    [[ "$plugin" == fzf ]] && (( ! $+commands[fzf] )) && continue
    if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$plugin" || -d "$ZSH/plugins/$plugin" ]]; then
      plugins+=("$plugin")
    fi
  done
  unset plugin
  source "$ZSH/oh-my-zsh.sh"
fi

(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
