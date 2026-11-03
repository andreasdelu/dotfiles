# Dotfiles

My shell and editor setup for macOS and Linux. I use zsh with tmux and Neovim, plus a few macOS app configs.

## Setup

```sh
git clone https://github.com/andreasdelu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

Bootstrap lets you choose which steps to run. macOS uses Homebrew, while Linux package installation currently supports Ubuntu/Debian through `apt-get`. Other distributions can still link the configs.

Existing files are backed up before linking. macOS system defaults need a separate confirmation.

The macOS defaults include keyboard repeat speed (`KeyRepeat=2`) and delay (`InitialKeyRepeat=15`). Apply them through bootstrap or `bash scripts/set_macos_defaults.sh`, then log out and back in for keyboard changes to take effect.

The config needs zsh, tmux 3.3+ and Neovim 0.12+ with Tree-sitter CLI 0.26.1+. On Linux, the package step installs the editor tools under `~/.local/bin`, so restart your shell afterwards. Project dependencies and some formatter/LSP executables still need installing separately.

## Changing things

Edit the files in `config/`. The mappings in [maps/](maps/) link them into your home directory, so `config/zshrc` becomes `~/.zshrc`, for example.

After changing the mappings or optional features, run:

```sh
./scripts/setup_dotfiles.sh
```

Add `DRY_RUN=1 DOTFILES_ASSUME_YES=1` to preview the changes.

### Machine-local environment

Copy the example from the repo root, then edit the checkout paths for this machine:

```sh
cp config/zsh/env.sh.example config/zsh/env.sh
```

`config/zsh/env.sh` is gitignored and available at `~/.config/zsh/env.sh` through the existing directory link. `.zshrc` sources it before aliases and tool setup, and safely skips it when missing. It is shell code, separate from the restricted Ghostty preferences in `config/dotfiles/local.env`.

The example sets `PAX_REPO` and `LANDFOLK_HOME` for checkout paths, and `PAX_HOME` to `~/.pax` for mutable runtime state. Keep these distinct: pointing `PAX_HOME` at the checkout writes sessions and credentials into the repository. Move any existing definitions from `~/.zshenv` into this file to keep one source of truth, then start a new shell. The `pax`, `paxc`, `supervised`, and `pax-status` aliases are only defined when `PAX_REPO` is nonempty and `$PAX_REPO/bin/pax` is executable; there is no default checkout path.

### Optional Ghostty pane dimming

On macOS, copy `config/dotfiles/local.env.example` to `config/dotfiles/local.env` and set `DOTFILES_GHOSTTY_PANE_DIMMING=1`. This needs Ghostty on PATH and tmux 3.7+.

Run the linker again, reload Ghostty and start a fresh shell. For an existing tmux server, apply the flag and reload its config:

```sh
tmux set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING "${DOTFILES_GHOSTTY_PANE_DIMMING:-0}"
tmux source-file ~/.tmux.conf
```

Use `tmux -L <name>` for both commands if the server is named. An explicit environment value overrides `local.env`, so re-sourcing `.zshrc` won't replace an already-exported value.

## A few notes

- Ruby uses Sorbet for projects with `sorbet/config`. Ruby LSP is disabled, and the Landfolk API launcher needs Nix with flakes and the project's gems installed.
- Vorssaint settings are in [exports/vorssaint-settings.plist](exports/vorssaint-settings.plist). Import them manually through Settings → Advanced → Import settings.
- Checks live in [scripts/tests/](scripts/tests/). Linux has been tested in an Ubuntu arm64 container, but real login and LSP workflows still need testing.
