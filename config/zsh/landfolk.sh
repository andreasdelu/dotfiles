# Set PAX_REPO and LANDFOLK_HOME in ~/.config/zsh/env.sh.
# Copy env.sh.example to env.sh and customize the checkout paths.
# Pax aliases require PAX_REPO; LANDFOLK_HOME is available for project helpers.

# Nix must load before PATH and Oh My Zsh setup.
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

alias md='make dev'
alias mt='make types'
alias td='task dev'
alias tdg='task dev:enable-goodjob'
alias tgqd='task graphql:dump'

if [[ -n ${PAX_REPO:-} && -x "$PAX_REPO/bin/pax" ]]; then
  alias pax='"$PAX_REPO/bin/pax" --cwd "$PWD"'
  alias paxc='"$PAX_REPO/bin/pax" --cwd "$PWD" --continue'
  alias supervised='"$PAX_REPO/bin/pax" supervised'
  alias pax-status='"$PAX_REPO/bin/pax" pax-status'
fi
