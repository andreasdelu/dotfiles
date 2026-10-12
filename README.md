# Portable dotfiles

Shared zsh, tmux, and Neovim configuration. macOS uses Homebrew; Linux uses its
native package manager. The automated Linux package step currently supports
`apt-get` (Ubuntu/Debian); other distributions can link the config and add a
package-manager adapter under `scripts/install/linux/`.

Use zsh, tmux 3.3+ (3.7+ for pane dimming), and Neovim 0.12+ with Tree-sitter
CLI 0.26.1+. Homebrew is macOS-only.
Clipboard copying selects pbcopy, wl-copy, or xclip when available, otherwise
uses tmux's OSC 52 clipboard support. Oh My Zsh and executable-backed aliases
load only when their dependencies exist; Landfolk aliases are defined on every
machine.

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

`local.env` is gitignored and accepts only `DOTFILES_GHOSTTY_PANE_DIMMING=0`
or `=1`, blank lines, and whole-line comments. It is data, not shell code.
Bootstrap and the linked zsh entrypoint load it before setup. An explicit
process value (including `0` or an empty value) wins over the file default;
only exactly `1` enables pane dimming. Remove retired preference lines from an
existing `local.env` before updating this checkout.

- `DOTFILES_GHOSTTY_PANE_DIMMING=1`: on macOS, link the optional Ghostty shader
  and enable tmux metadata/hooks when Ghostty is on PATH and tmux is 3.7+.
  Only Ghostty clients receive palette metadata. Other terminals retain the core.

On macOS, selecting the Brewfile step installs CLI tools and desktop apps;
selecting the link step links their configs. System defaults are a separate
step with an additional confirmation. No desktop environment flag is needed.
Installers live in `scripts/install/macos/` and `scripts/install/linux/`;
shared Oh My Zsh setup stays directly in `scripts/install/`. The Brewfile
remains at the repo root for Homebrew.

Lazygit is a terminal tool, so its native config path stays in the core on both
platforms. Ghostty config and pane-dimming links are macOS-only; Linux desktop
setup is not supported yet.

**Run the `bootstrap.sh` script**

```shell
./bootstrap.sh
```

On apt-based Linux (x86_64 or arm64), select the Linux packages step before
linking. On a fresh machine, you can select Oh My Zsh in the same run: apt
installs `zsh` first. Selecting Oh My Zsh without `zsh` installed or the apt
step selected stops with an error rather than starting its installer. The apt
step installs core command-line dependencies, then downloads the
latest stable Neovim and Tree-sitter CLI from their official GitHub releases,
checks the published SHA-256 digests, verifies the binaries run on this distro,
and links them under `~/.local/bin`. Existing files there are never overwritten;
rerunning can update links the installer owns. Restart your shell to pick up
the new PATH. The Linux installer does not install optional desktop apps,
Nix/Ruby project dependencies, or all Neovim formatter/LSP executables.
A fresh Ubuntu 26.04 arm64 container passed the real apt-to-editor install
(Neovim 0.12.6, Tree-sitter CLI 0.27.1), linking, interactive zsh startup,
tmux startup, and headless Neovim config startup with fresh plugins. A real
Linux login, x86_64, and plugin/LSP workflows still need testing. Linux desktop apps and
Ghostty pane dimming are intentionally out of scope.

## Symlinks

The mappings in [maps/](maps/) use `common.txt` plus an OS file (`macos.txt`
for Darwin, `linux.txt` for Linux). Adding another OS means adding its lowercase
`uname -s` map; Linux distributions share `linux.txt`. Shared source files
remain under `config/`; only differing destinations and macOS app links live
in platform maps.
`scripts/setup_dotfiles.sh` links files from `config/` into your home directory
and backs up existing files and symlinks into a unique `.backup_*` folder in
the repo before replacing them. It creates that folder only when needed and
validates both selected maps before making changes. Source names do not need
leading dots: `config/zshrc`
becomes `~/.zshrc`, `config/tmux/` becomes `~/.tmux/`, and so on.

`config/zshrc` is an ordered loader for `config/zsh/*.sh`, linked to
`~/.config/zsh/` by the common map. `landfolk.sh` groups the Landfolk aliases,
early Nix setup, and Pax aliases; Nix and Pax still require their local files.
There is no per-machine opt-in, so Landfolk aliases are defined on every Mac.
Add new fragments to the loader explicitly rather than relying on glob order.

### Vorssaint settings

`exports/vorssaint-settings.plist` is an export from Vorssaint's **Settings → Advanced → Export settings**. It preserves the selected features, modules, layout, and preferences without linking the live macOS preferences plist or carrying over machine-specific paths. Vorssaint is installed by the macOS Brewfile step; after installing, restore the settings with **Settings → Advanced → Import settings** and select this file. Bootstrap does not import it or overwrite existing Vorssaint preferences.

When changing the setup, export again to this file and review the changes before committing. Keep personal notes and local device/permission state out of the repo; permissions may still need to be granted on a new Mac.

## Applying preferences

Run `./scripts/setup_dotfiles.sh` after changing link preferences (or select
linking in bootstrap). `DRY_RUN=1 DOTFILES_ASSUME_YES=1 ./scripts/setup_dotfiles.sh`
previews the same decisions. Disabling removes only exact links owned by this
checkout; other files remain untouched. Existing apps are not uninstalled and
macOS system defaults are not reversed.

Start a fresh shell after changing `local.env`. Re-sourcing `.zshrc` retains an
already-exported value by design; unset `DOTFILES_GHOSTTY_PANE_DIMMING` first
if you want to reread the file default. Neovim and new tmux servers inherit
from their launching shell. Direct GUI/service launches do not read `.zshrc`:
launch through the configured shell or supply the environment explicitly.

### Ghostty and existing tmux servers

Ghostty does not read these environment flags. On macOS, the linker adds/removes
the tracked `pane-dimming.conf` fragment; `config/ghostty/config` uses Ghostty's native
`config-file = ?~/.config/ghostty/pane-dimming.conf` optional inclusion. This
syntax and traversal are tested with Ghostty 1.3.1, not assumed environment
interpolation. After relinking, reload Ghostty's configuration (or restart it).

Existing tmux servers retain their original environment. In a fresh configured
shell, apply the pane-dimming flag to the intended server, then reload:

```shell
tmux set-environment -g DOTFILES_GHOSTTY_PANE_DIMMING "${DOTFILES_GHOSTTY_PANE_DIMMING:-0}"
tmux source-file ~/.tmux.conf
```

Use `tmux -L <name>` consistently for a named server. Restarting that server
from the configured shell is an alternative, but ends its sessions. Reloading
removes this repo's dimming hooks and clears Ghostty palette metadata when off;
unrelated hooks are preserved. Already-running applications/popups keep their
environment: close/reopen them. Relinking alone does not reload a live server,
and tmux reload does not change the Ghostty shader include. The base tmux
config sources `~/.tmux/features.conf`; the pane-dimming handler owns its
setup and cleanup on each reload.

## Notes

- `bootstrap.sh` opens with a zero-dependency checkbox UI. Use ↑/↓ or `j`/`k` to move, Space to toggle, `a` to toggle all, Enter to run, and Esc/`q` to quit.
- If a real terminal is not available, the bootstrap falls back to plain yes/no prompts.
- Selected steps run with styled progress headers, success/failure markers, and elapsed time.
- The repo keeps `config/zshrc` as the source for the linked `~/.zshrc`.
- Neovim logs like `.nvimlog` are ignored and should not be tracked.
- macOS defaults always require a separate confirmation, even with `DOTFILES_ASSUME_YES=1`, and write per-user settings without `sudo`.
- `bash scripts/tests/test_portability.sh` checks syntax, isolated shell startup, flag precedence, and temporary-HOME linking/backups. Its Linux map check simulates `uname`; it is not an actual Linux runtime test.
- `bash scripts/tests/test_bootstrap.sh` checks simulated OS package steps, macOS-only Brewfile casks, TPM setup without Homebrew, and direct defaults-helper consent, with mutations stubbed out. It does not run apt or the Linux editor installer.
- `bash scripts/tests/test_tmux_features.sh` uses a private socket and temporary HOME to test feature off/on/off and missing dependencies without touching your live server. With `uv` and `xterm-ghostty` terminfo, it also attaches a real PTY client to test upgrade-from-old-config and detach cleanup.
- `bash scripts/tests/test_pane_metadata.sh` checks popup/emitter gating with stubbed tmux queries.
- `bash scripts/tests/test_ghostty.sh` validates optional config inclusion using the installed Ghostty CLI; visual shader rendering still needs a real Ghostty window.
- `bash scripts/tests/test_nvim.sh` checks headless startup with both pane-dimming states and an isolated copy of installed plugins (skips if none are installed). It does not test real-project LSP attachment.
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
  `bash scripts/tests/test_nvim.sh /absolute/path/to/apps/api/app/models/application_record.rb`
  additionally attempts a real attachment. Its temporary HOME needs Nix settings
  supplied explicitly (for example `NIX_CONFIG='experimental-features = nix-command flakes'`)
  and access to installed project gems. The API Nix shell runs its normal local
  service hooks; this check is opt-in and does not install missing gems.
