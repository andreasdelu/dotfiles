#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Linux ]]; then
  echo "The editor installer requires Linux." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) nvim_asset=nvim-linux-x86_64.tar.gz; tree_asset=tree-sitter-linux-x64.gz ;;
  aarch64) nvim_asset=nvim-linux-arm64.tar.gz; tree_asset=tree-sitter-linux-arm64.gz ;;
  *) echo "Unsupported editor architecture: $(uname -m)" >&2; exit 1 ;;
esac

releases="$HOME/.local/share/dotfiles-tools"
bin="$HOME/.local/bin"
mkdir -p "$releases" "$bin"
check_link() {
  local link="$1" directory="$2"
  if [[ -L "$link" ]]; then
    [[ "$(readlink "$link")" == "$directory/"* ]] || {
      echo "Refusing to replace an unmanaged $link" >&2; return 1;
    }
  elif [[ -e "$link" ]]; then
    echo "Refusing to replace an unmanaged $link" >&2
    return 1
  fi
}
check_link "$bin/nvim" "$releases/nvim"
check_link "$bin/tree-sitter" "$releases/tree-sitter"

mkdir -p "$releases/nvim" "$releases/tree-sitter"

stage="$(mktemp -d "$releases/.install.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
release_asset() {
  local repo="$1" asset="$2" minimum="$3"
  curl -fsSL --retry 3 "https://api.github.com/repos/$repo/releases/latest" -o "$stage/release.json"
  python3 - "$stage/release.json" "$repo" "$asset" "$minimum" <<'PY'
import json
import re
import sys

with open(sys.argv[1]) as source:
    data = json.load(source)
tag = data.get('tag_name', '')
match = re.fullmatch(r'v(\d+)\.(\d+)\.(\d+)', tag)
minimum = tuple(map(int, sys.argv[4].split('.')))
if data.get('draft') or data.get('prerelease') or not match or tuple(map(int, match.groups())) < minimum:
    sys.exit(f'Latest stable {sys.argv[2]} is not compatible with this config')
for asset in data['assets']:
    if asset['name'] == sys.argv[3]:
        digest = asset.get('digest', '')
        url = asset['browser_download_url']
        if not re.fullmatch(r'sha256:[0-9a-f]{64}', digest) or not url.startswith(f'https://github.com/{sys.argv[2]}/releases/download/{tag}/'):
            sys.exit('Release asset has no trustworthy SHA-256 digest or URL')
        print(tag, url, digest.removeprefix('sha256:'), sep='\t')
        break
else:
    sys.exit(f'Release has no {sys.argv[3]} asset')
PY
}

metadata="$(release_asset neovim/neovim "$nvim_asset" 0.12.0)"
IFS=$'\t' read -r tag url checksum <<< "$metadata"
nvim_dir="$releases/nvim/$tag"
if [[ ! -d "$nvim_dir" ]]; then
  curl -fsSL --retry 3 "$url" -o "$stage/nvim.tar.gz"
  printf '%s  %s\n' "$checksum" "$stage/nvim.tar.gz" | sha256sum -c -
  mkdir "$stage/nvim"
  tar -xzf "$stage/nvim.tar.gz" -C "$stage/nvim" --strip-components=1
  [[ -x "$stage/nvim/bin/nvim" ]] || { echo 'Neovim archive has no executable' >&2; exit 1; }
  mv "$stage/nvim" "$nvim_dir"
fi
[[ -x "$nvim_dir/bin/nvim" ]] || { echo "Broken Neovim installation: $nvim_dir" >&2; exit 1; }

metadata="$(release_asset tree-sitter/tree-sitter "$tree_asset" 0.26.1)"
IFS=$'\t' read -r tag url checksum <<< "$metadata"
tree_dir="$releases/tree-sitter/$tag"
if [[ ! -d "$tree_dir" ]]; then
  curl -fsSL --retry 3 "$url" -o "$stage/tree-sitter.gz"
  printf '%s  %s\n' "$checksum" "$stage/tree-sitter.gz" | sha256sum -c -
  mkdir "$stage/tree-sitter"
  gzip -dc "$stage/tree-sitter.gz" > "$stage/tree-sitter/tree-sitter"
  chmod +x "$stage/tree-sitter/tree-sitter"
  mv "$stage/tree-sitter" "$tree_dir"
fi
[[ -x "$tree_dir/tree-sitter" ]] || { echo "Broken Tree-sitter CLI installation: $tree_dir" >&2; exit 1; }

# Do not replace working links with release binaries incompatible with this distro.
"$nvim_dir/bin/nvim" --version >/dev/null || { echo "Neovim is not runnable on this Linux version" >&2; exit 1; }
"$tree_dir/tree-sitter" --version >/dev/null || { echo "Tree-sitter is not runnable on this Linux version" >&2; exit 1; }

ln -sfnT "$nvim_dir/bin/nvim" "$bin/nvim"
ln -sfnT "$tree_dir/tree-sitter" "$bin/tree-sitter"
"$bin/nvim" --version | head -n 1
"$bin/tree-sitter" --version
echo "Installed under $bin; the linked zsh config adds it to PATH."
