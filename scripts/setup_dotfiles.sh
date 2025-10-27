#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/config"
MAPS_FILE="${MAPS_FILE:-$REPO_DIR/maps.txt}"
BACKUP_DIR="${REPO_DIR}/.backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN="${DRY_RUN:-0}"

log() { printf "%s\n" "$*"; }
run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        log "[DRY] $*"
    else
        eval "$@"
    fi
}

confirm() {
    local prompt="${1:-Proceed?} [y/N] "
    read -n 1 -r -p "$prompt" reply
    echo
    [[ "$reply" =~ ^[Yy]$ ]]
}

backup_file() {
    local path="$1"
    run "mkdir -p \"$BACKUP_DIR\""
    local rel="${path/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    run "mkdir -p \"$(dirname "$dest")\""
    run "mv \"$path\" \"$dest\""
    log "Backed up: $path -> $dest"
}

ensure_parent_dir() {
    local parent
    parent="$(dirname "$1")"
    [[ -d "$parent" ]] && return 0
    run "mkdir -p \"$parent\""
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
        run "rm -f \"$dst\""
    elif [[ -e "$dst" ]]; then
        log "Found existing file/dir: $dst"
        backup_file "$dst"
    fi

    ensure_parent_dir "$dst"
    run "ln -s \"$src\" \"$dst\""
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

        # split src=dst (src is relative to config/)
        src_rel="${line%%=*}"
        dst_raw="${line#*=}"
        src_rel="$(printf "%s" "$src_rel" | awk '{$1=$1;print}')"
        dst_raw="$(printf "%s" "$dst_raw" | awk '{$1=$1;print}')"

        src_abs="$SRC_DIR/$src_rel"
        dst_abs="$(expand_tilde "$dst_raw")"

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
