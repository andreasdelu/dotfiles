#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/common.sh"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/config"
. "$SRC_DIR/dotfiles/env.sh"
dotfiles_load_preferences "$SRC_DIR/dotfiles/local.env"
BACKUP_DIR=""
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
    if [[ -z "$BACKUP_DIR" ]]; then
        if [[ "$DRY_RUN" == 1 ]]; then
            BACKUP_DIR="$REPO_DIR/.backup_$(date +%Y%m%d_%H%M%S).DRY_RUN"
        else
            BACKUP_DIR="$(mktemp -d "$REPO_DIR/.backup_$(date +%Y%m%d_%H%M%S).XXXXXX")"
        fi
    fi
    local rel="${path/#$HOME\//}"
    local dest="$BACKUP_DIR/$rel"
    if [[ -e "$dest" || -L "$dest" ]]; then
        log "Refusing to overwrite backup: $dest" >&2
        return 1
    fi
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
        log "Backing up existing symlink: $dst -> $current"
        backup_file "$dst"
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

process_maps_file() {
    local MAPS_FILE="$1" mode="${2:-apply}"
    if [[ ! -f "$MAPS_FILE" ]]; then
        log "No $MAPS_FILE found"; return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # strip comments
        line="${line%%#*}"
        # trim whitespace
        line="$(printf "%s" "$line" | awk '{$1=$1;print}')"
        [[ -z "$line" ]] && continue

        # Validate both maps before the first link or backup is touched.
        local condition="all" enabled=1
        if [[ "$line" == *'|'* ]]; then
            condition="${line##*|}"
            line="${line%|*}"
        fi
        case "$condition" in
            all|pane-dimming) ;;
            *) log "Unknown map condition: $condition" >&2; return 1 ;;
        esac

        # split src=dst (src is relative to config/)
        if [[ "$line" != *=* || "$line" == *'|'* ]]; then
            log "Invalid map entry in $MAPS_FILE: $line" >&2; return 1
        fi
        local src_rel="${line%%=*}"
        local dst_raw="${line#*=}"
        src_rel="$(printf "%s" "$src_rel" | awk '{$1=$1;print}')"
        dst_raw="$(printf "%s" "$dst_raw" | awk '{$1=$1;print}')"
        if [[ -z "$src_rel" || "$dst_raw" != "~/"* ]]; then
            log "Invalid map entry in $MAPS_FILE: $line" >&2; return 1
        fi
        [[ "$mode" == validate ]] && continue

        if [[ "$condition" == pane-dimming ]]; then
            [[ "$DOTFILES_GHOSTTY_PANE_DIMMING" == 1 ]] || enabled=0
            command -v ghostty >/dev/null 2>&1 || enabled=0
            local tmux_version
            tmux_version="$(tmux -V 2>/dev/null || true)"
            if [[ "$tmux_version" =~ ^tmux\ ([0-9]+)\.([0-9]+) ]]; then
                (( BASH_REMATCH[1] > 3 || (BASH_REMATCH[1] == 3 && BASH_REMATCH[2] >= 7) )) || enabled=0
            else
                enabled=0
            fi
        fi

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

maps_mode() {
    if [[ -n "${MAPS_FILE:-}" ]]; then
        process_maps_file "$MAPS_FILE" validate
        process_maps_file "$MAPS_FILE"
        return
    fi

    local platform platform_maps
    platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
    [[ "$platform" == darwin ]] && platform=macos
    platform_maps="$REPO_DIR/maps/$platform.txt"
    if [[ ! -f "$REPO_DIR/maps/common.txt" || ! -f "$platform_maps" ]]; then
        log "Missing map for $platform; add maps/$platform.txt before linking." >&2
        return 1
    fi
    process_maps_file "$REPO_DIR/maps/common.txt" validate
    process_maps_file "$platform_maps" validate
    process_maps_file "$REPO_DIR/maps/common.txt"
    process_maps_file "$platform_maps"
}

main() {
    log "Dotfiles setup (sources in config/, maps in maps/)"
    log "Repo: $REPO_DIR"
    log "Source dir: $SRC_DIR"
    log "Backups: created in the repo only when needed"
    log ""
    if ! confirm "Proceed with linking dotfiles?"; then
        log "Aborted."; exit 1
    fi
    maps_mode
    log ""
    if [[ -n "$BACKUP_DIR" ]]; then
        log "Done. Backups in: $BACKUP_DIR"
    else
        log "Done. No backups needed."
    fi
}

main "$@"
