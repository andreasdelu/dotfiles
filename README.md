# Portable dotfiles

Cross-platform zsh, tmux, and Neovim configuration, with macOS setup helpers.
Compatibility checks keep missing tools and macOS-only paths out of Linux setup;
editor plugins are not classified as Mac-only. Install Linux packages with your
system package manager (there is no Linux package installer here).

Use zsh, tmux 3.3+ (3.7+ for pane dimming), and Neovim 0.11+; the active
Tree-sitter configuration targets Neovim 0.12. Homebrew is optional on Linux.
Clipboard copying selects pbcopy, wl-copy, or xclip when available, otherwise
uses tmux's OSC 52 clipboard support. Oh My Zsh and personal command aliases
are loaded only when their files exist.

## Installation

**Clone this repository**

```shell
git clone https://github.com/andreasdelu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

**Choose optional features**

```shell
cp config/dotfiles/local.env.example config/dotfiles/local.env
# Edit local.env: set only the features you want to 1.
```

`local.env` is gitignored and accepts only the three documented `NAME=0` or
`NAME=1` assignments, blank lines, and whole-line comments. It is data, not shell
code. Bootstrap and the linked zsh entrypoint load it before setup. Explicit
process environment values (including `0` or an empty value) win over file
defaults; only exactly `1` enables a feature. Unset flags are off on every OS.

- `DOTFILES_MACOS_DESKTOP=1`: macOS Homebrew casks, Ghostty/Karabiner/LinearMouse
  config links, and the separately confirmed macOS-defaults step. It does not
  install anything on Linux. Config links can be staged before installing apps.
- `DOTFILES_GHOSTTY_PANE_DIMMING=1`: reserved for the optional Ghostty/tmux pane dimmer.
- `DOTFILES_PI_OVERWATCH=1`: reserved for optional Pi Overwatch integration.

Lazygit is a terminal tool, so its native config path stays in the core on both
platforms. The Linux Ghostty config remains usable independently of macOS apps.

**Run the `bootstrap.sh` script**

```shell
./bootstrap.sh
```

## Symlinks

The mapping in [maps.txt](maps.txt) drives the symlink setup. `scripts/setup_dotfiles.sh` links files from `config/` into your home directory and backs up existing files into a timestamped `.backup_*` folder in the repo before replacing them.

## Applying preferences

Run `./scripts/setup_dotfiles.sh` after changing link preferences (or select
linking in bootstrap). `DRY_RUN=1 DOTFILES_ASSUME_YES=1 ./scripts/setup_dotfiles.sh`
previews the same decisions. Disabling removes only exact links owned by this
checkout; other files remain untouched. Existing apps are not uninstalled and
macOS system defaults are not reversed.

Start a fresh shell after changing `local.env`. Re-sourcing `.zshrc` retains
already-exported values by design; unset the three flags first if you want to
reread file defaults. Neovim and new tmux servers inherit from their launching
shell. Direct GUI/service launches do not read `.zshrc`: launch through the
configured shell or supply the environment explicitly. Direct `brew bundle`
likewise uses its process environment, not `local.env`.

## Notes

- `bootstrap.sh` opens with a zero-dependency checkbox UI. Use ↑/↓ or `j`/`k` to move, Space to toggle, `a` to toggle all, Enter to run, and Esc/`q` to quit.
- If a real terminal is not available, the bootstrap falls back to plain yes/no prompts.
- Selected steps run with styled progress headers, success/failure markers, and elapsed time.
- The repo keeps `config/.zshrc` as the symlinked shell entrypoint.
- Neovim logs like `.nvimlog` are ignored and should not be tracked.
- macOS defaults always require a separate confirmation, even with `DOTFILES_ASSUME_YES=1`.
- `bash scripts/test_portability.sh` checks syntax, isolated shell startup, and temporary-HOME linking/backups. Its Linux map check simulates `uname`; it is not an actual Linux runtime test.
- Ruby LSP remains disabled; Sorbet still requires `sorbet/config`. The existing Landfolk `Documents/.../apps/api` routing through Nix is preserved, not generalized to unrelated Ruby projects.
