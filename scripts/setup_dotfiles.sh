#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/config"
. "$SRC_DIR/dotfiles/env.sh"
dotfiles_load_preferences "$SRC_DIR/dotfiles/local.env"
MAPS_FILE="${MAPS_FILE:-$REPO_DIR/maps.txt}"
BACKUP_DIR="${REPO_DIR}/.backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN="${DRY_RUN:-0}"

log() { printf "%s\n" "$*"; }

run_cmd() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '[DRY]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}

backup_file() {
    local path="$1"
    run_cmd mkdir -p "$BACKUP_DIR"
    local rel="${path/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    run_cmd mkdir -p "$(dirname "$dest")"
    run_cmd mv "$path" "$dest"
    log "Backed up: $path -> $dest"
}

ensure_parent_dir() {
    local parent
    parent="$(dirname "$1")"
    [[ -d "$parent" ]] && return 0
    run_cmd mkdir -p "$parent"
}

link_file() {
    local src="$1" dst="$2"

    if [[ -L "$dst" ]]; then
        local current
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            log "OK (linked): $dst"
            return 0
        fi
        log "Replacing existing symlink: $dst -> $current"
        run_cmd rm -f "$dst"
    elif [[ -e "$dst" ]]; then
        log "Found existing file/dir: $dst"
        backup_file "$dst"
    fi

    ensure_parent_dir "$dst"
    run_cmd ln -s "$src" "$dst"
    log "Linked: $dst -> $src"
}

expand_tilde() {
    local p="$1"
    [[ "$p" == "~/"* ]] && printf "%s\n" "${p/#\~/$HOME}" || printf "%s\n" "$p"
}

maps_mode() {
    if [[ ! -f "$MAPS_FILE" ]]; then
        log "No $MAPS_FILE found"; return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # strip comments
        line="${line%%#*}"
        # trim whitespace
        line="$(printf "%s" "$line" | awk '{$1=$1;print}')"
        [[ -z "$line" ]] && continue

        # Fixed compatibility/preference conditions, not a general expression DSL.
        local condition="all" enabled=1
        if [[ "$line" == *'|'* ]]; then
            condition="${line##*|}"
            line="${line%|*}"
        fi
        case "$condition" in
            all) ;;
            macos) [[ "$(uname -s)" == Darwin ]] || enabled=0 ;;
            linux) [[ "$(uname -s)" == Linux ]] || enabled=0 ;;
            macos-desktop) [[ "$(uname -s)" == Darwin && "$DOTFILES_MACOS_DESKTOP" == 1 ]] || enabled=0 ;;
            *) log "Unknown map condition: $condition" >&2; return 1 ;;
        esac

        # split src=dst (src is relative to config/)
        local src_rel="${line%%=*}"
        local dst_raw="${line#*=}"
        src_rel="$(printf "%s" "$src_rel" | awk '{$1=$1;print}')"
        dst_raw="$(printf "%s" "$dst_raw" | awk '{$1=$1;print}')"

        local src_abs="$SRC_DIR/$src_rel"
        local dst_abs
        dst_abs="$(expand_tilde "$dst_raw")"

        if [[ "$enabled" == 0 ]]; then
            # Reapplying off removes only our exact optional symlink. Never
            # delete user-owned files, uninstall apps, or reverse system defaults.
            if [[ -L "$dst_abs" && "$(readlink "$dst_abs")" == "$src_abs" ]]; then
                run_cmd rm -f "$dst_abs"
                log "Unlinked (disabled): $dst_abs"
            fi
            continue
        fi

        if [[ ! -e "$src_abs" ]]; then
            log "WARN: source missing under config/: $src_rel" >&2
            continue
        fi

        link_file "$src_abs" "$dst_abs"
    done < "$MAPS_FILE"
}

main() {
    log "Dotfiles setup (maps under config/)"
    log "Repo: $REPO_DIR"
    log "Source dir: $SRC_DIR"
    log "Backup dir: $BACKUP_DIR"
    log ""
    if ! confirm "Proceed with linking dotfiles?"; then
        log "Aborted."; exit 1
    fi
    maps_mode
    log ""
    log "Done. Backups in: $BACKUP_DIR"
}

main "$@"
