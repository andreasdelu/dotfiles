# My dotfiles and macOS config

This repo is primarily set up for macOS. `bootstrap.sh` walks through system defaults, package/tool installation, GitHub auth, and symlinking the files in `config/` onto the expected paths on your machine.

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
