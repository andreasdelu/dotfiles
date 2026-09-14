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

**Run the `bootstrap.sh` script**

```shell
./bootstrap.sh
```

## Symlinks

The mapping in [maps.txt](maps.txt) drives the symlink setup. `scripts/setup_dotfiles.sh` links files from `config/` into your home directory and backs up existing files into a timestamped `.backup_*` folder in the repo before replacing them.

## Notes

- `bootstrap.sh` opens with a zero-dependency checkbox UI. Use ↑/↓ or `j`/`k` to move, Space to toggle, `a` to toggle all, Enter to run, and Esc/`q` to quit.
- If a real terminal is not available, the bootstrap falls back to plain yes/no prompts.
- Selected steps run with styled progress headers, success/failure markers, and elapsed time.
- The repo keeps `config/.zshrc` as the symlinked shell entrypoint.
- Neovim logs like `.nvimlog` are ignored and should not be tracked.
- macOS defaults always require a separate confirmation, even with `DOTFILES_ASSUME_YES=1`.
- `bash scripts/test_portability.sh` checks syntax, isolated shell startup, and temporary-HOME linking/backups. Its Linux map check simulates `uname`; it is not an actual Linux runtime test.
- Ruby LSP remains disabled; Sorbet still requires `sorbet/config`. The existing Landfolk `Documents/.../apps/api` routing through Nix is preserved, not generalized to unrelated Ruby projects.
