# Nix must load before PATH and Oh My Zsh setup.
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

alias md='make dev'
alias mt='make types'
alias td='task dev'
alias tdg='task dev:enable-goodjob'
alias tgqd='task graphql:dump'

if [[ -x "$HOME/Documents/pax/bin/pax" ]]; then
  alias pax='~/Documents/pax/bin/pax --cwd "$PWD"'
  alias paxc='~/Documents/pax/bin/pax --cwd "$PWD" --continue'
fi
