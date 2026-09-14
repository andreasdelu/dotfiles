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
- `DOTFILES_GHOSTTY_PANE_DIMMING=1`: Ghostty shader and tmux metadata/hooks.
  Requires Ghostty on PATH and tmux 3.7+; on macOS also enable desktop config.
  Only Ghostty clients receive palette metadata. Other terminals retain the core.
- `DOTFILES_PI_OVERWATCH=1`: enable TWM's Overwatch reader in the shell alias
  and tmux popup. Requires the TWM binary at
  `~/.tmux/plugins/tmux-worktree-manager/dist/twm` and producer state directory
  `~/.pi/overwatch/agents` (install/run Pi Overwatch separately). TWM remains
  available without Overwatch. No Pi extension is installed or removed here.

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

### Ghostty and existing tmux servers

Ghostty does not read these environment flags. The linker adds/removes the
tracked `pane-dimming.conf` fragment; `.ghostty` uses Ghostty's native
`config-file = ?~/.config/ghostty/pane-dimming.conf` optional inclusion. This
syntax and traversal are tested with Ghostty 1.3.1, not assumed environment
interpolation. After relinking, reload Ghostty's configuration (or restart it).

Existing tmux servers retain their original environment. In a fresh configured
shell, apply the current flags explicitly to the intended server, then reload:

```shell
tmux set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING "${DOTFILES_GHOSTTY_PANE_DIMMING:-0}"
tmux set-environment -g DOTFILES_PI_OVERWATCH "${DOTFILES_PI_OVERWATCH:-0}"
tmux source-file ~/.tmux.conf
```

Use `tmux -L <name>` consistently for a named server. Restarting that server
from the configured shell is an alternative, but ends its sessions. Reloading
removes this repo's dimming hooks and clears Ghostty palette metadata when off;
unrelated hooks are preserved. Already-running applications/popups keep their
environment: close/reopen them. Relinking alone does not reload a live server,
and tmux reload does not change the Ghostty shader include.

## Notes

- `bootstrap.sh` opens with a zero-dependency checkbox UI. Use ↑/↓ or `j`/`k` to move, Space to toggle, `a` to toggle all, Enter to run, and Esc/`q` to quit.
- If a real terminal is not available, the bootstrap falls back to plain yes/no prompts.
- Selected steps run with styled progress headers, success/failure markers, and elapsed time.
- The repo keeps `config/.zshrc` as the symlinked shell entrypoint.
- Neovim logs like `.nvimlog` are ignored and should not be tracked.
- macOS defaults always require a separate confirmation, even with `DOTFILES_ASSUME_YES=1`.
- `bash scripts/test_portability.sh` checks syntax, isolated shell startup, flag precedence, and temporary-HOME linking/backups. Its Linux map check simulates `uname`; it is not an actual Linux runtime test.
- `bash scripts/test_bootstrap.sh` checks simulated menu/cask filtering and direct defaults-helper consent, with mutations stubbed out.
- `bash scripts/test_tmux_features.sh` uses a private socket and temporary HOME to test feature off/on/off and missing dependencies without touching your live server. With `uv` and `xterm-ghostty` terminfo, it also attaches a real PTY client to test upgrade-from-old-config and detach cleanup.
- `bash scripts/test_pane_metadata.sh` checks popup/emitter gating with stubbed tmux queries.
- `bash scripts/test_ghostty.sh` validates optional config inclusion using the installed Ghostty CLI; visual shader rendering still needs a real Ghostty window.
- `bash scripts/test_nvim.sh` checks headless startup with both flag states and an isolated copy of installed plugins (skips if none are installed). It does not test real-project LSP attachment.
- Ruby LSP remains disabled; Sorbet still requires `sorbet/config`. Landfolk API
  detection uses `apps/api`, the root package name `landfolk`, `flake.nix`,
  `apps/api/shell.nix`, and `bin/srb`, not a personal checkout path. It runs
  `nix develop ../..#api -c ./bin/srb tc --lsp --disable-watchman` from that API
  directory. Other Sorbet projects retain `srb` from PATH.
- Install/configure Nix with flakes and the project's bundle before using this
  launcher. Moving a checkout no longer requires editing Neovim; missing Ruby
  dependencies still require project setup. Syntax Tree/Rubocop keep their
  existing project-binstub behavior and need the correct shell environment.
- `nvim --headless -u NONE -l config/nvim/lua/config/ruby.test.lua` checks relocated
  roots, unrelated projects, `sorbet/config` gating, and exact command/cwd routing.
  `bash scripts/test_nvim.sh /absolute/path/to/apps/api/app/models/application_record.rb`
  additionally attempts a real attachment. Its temporary HOME needs Nix settings
  supplied explicitly (for example `NIX_CONFIG='experimental-features = nix-command flakes'`)
  and access to installed project gems. The API Nix shell runs its normal local
  service hooks; this check is opt-in and does not install missing gems.
