#!/usr/bin/env bash

# Small zero-dependency checkbox picker for first-run bootstrap.
# Writes UI to stderr and selected item ids to stdout, so callers can capture it.

if ! declare -F confirm >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

checkbox_menu_plain() {
  local prompt="$1"
  shift

  local item id label
  printf "%s\n\n" "$prompt" >&2
  for item in "$@"; do
    id="${item%%|*}"
    label="${item#*|}"
    if confirm "$label?"; then
      printf "%s\n" "$id"
    fi
  done
}

checkbox_menu() {
  local prompt="$1"
  shift

  local ids=()
  local labels=()
  local selected=()
  local item id label

  for item in "$@"; do
    id="${item%%|*}"
    label="${item#*|}"
    ids+=("$id")
    labels+=("$label")
    selected+=(1)
  done

  if [[ ${#ids[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 || "${TERM:-}" == "dumb" ]]; then
    checkbox_menu_plain "$prompt" "$@"
    return
  fi

  local cursor=0
  local key key2 key3
  local reset="" bold="" dim="" cyan="" green="" yellow="" gray=""
  local old_stty
  old_stty="$(stty -g 2>/dev/null || true)"

  if [[ -z "${NO_COLOR:-}" ]]; then
    reset=$'\033[0m'
    bold=$'\033[1m'
    dim=$'\033[2m'
    cyan=$'\033[36m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    gray=$'\033[90m'
  fi

  printf '\033[?1049h\033[?25l' >&2
  stty -echo -icanon min 1 time 0
  trap '[[ -n "${old_stty:-}" ]] && stty "$old_stty" 2>/dev/null || true; printf "\033[?25h\033[?1049l" >&2; exit 130' INT TERM

  while true; do
    printf '\033[H\033[2J' >&2

    local i selected_count=0
    for ((i = 0; i < ${#selected[@]}; i++)); do
      [[ ${selected[$i]} -eq 1 ]] && selected_count=$((selected_count + 1))
    done

    printf '%b✦ %s%b\n' "$bold$cyan" "$prompt" "$reset" >&2
    printf '%b%s/%s steps selected%b\n\n' "$dim" "$selected_count" "${#ids[@]}" "$reset" >&2

    local pointer mark mark_color label_color
    for ((i = 0; i < ${#ids[@]}; i++)); do
      pointer=" "
      mark=" "
      mark_color="$gray"
      label_color="$dim"

      if [[ ${selected[$i]} -eq 1 ]]; then
        mark="✓"
        mark_color="$green"
        label_color="$bold"
      fi

      if [[ $i -eq $cursor ]]; then
        pointer="❯"
        label_color="$bold$cyan"
      fi

      printf '%b%s%b %b[%s]%b %b%s%b\n' \
        "$cyan" "$pointer" "$reset" \
        "$mark_color" "$mark" "$reset" \
        "$label_color" "${labels[$i]}" "$reset" >&2
    done

    printf '\n%bControls%b  %b↑/↓%b or %bj/k%b move  %bSpace%b toggle  %ba%b all/none  %bEnter%b run  %bEsc/q%b quit\n' \
      "$gray" "$reset" \
      "$yellow" "$reset" "$yellow" "$reset" \
      "$yellow" "$reset" "$yellow" "$reset" "$yellow" "$reset" "$yellow" "$reset" >&2

    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        IFS= read -rsn1 -t 0.1 key2 || key2=""
        if [[ -z "$key2" ]]; then
          [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null || true
          printf '\033[?25h\033[?1049l' >&2
          trap - INT TERM
          return 130
        fi

        IFS= read -rsn1 -t 0.1 key3 || key3=""
        case "$key2$key3" in
          "[A")
            if [[ $cursor -gt 0 ]]; then
              cursor=$((cursor - 1))
            else
              cursor=$((${#ids[@]} - 1))
            fi
            ;;
          "[B")
            if [[ $cursor -lt $((${#ids[@]} - 1)) ]]; then
              cursor=$((cursor + 1))
            else
              cursor=0
            fi
            ;;
        esac
        ;;
      k|K)
        if [[ $cursor -gt 0 ]]; then
          cursor=$((cursor - 1))
        else
          cursor=$((${#ids[@]} - 1))
        fi
        ;;
      j|J)
        if [[ $cursor -lt $((${#ids[@]} - 1)) ]]; then
          cursor=$((cursor + 1))
        else
          cursor=0
        fi
        ;;
      " ")
        if [[ ${selected[$cursor]} -eq 1 ]]; then
          selected[$cursor]=0
        else
          selected[$cursor]=1
        fi
        ;;
      a|A)
        local all_selected=1
        for ((i = 0; i < ${#selected[@]}; i++)); do
          if [[ ${selected[$i]} -eq 0 ]]; then
            all_selected=0
            break
          fi
        done

        local next_value=1
        [[ $all_selected -eq 1 ]] && next_value=0
        for ((i = 0; i < ${#selected[@]}; i++)); do
          selected[$i]=$next_value
        done
        ;;
      q|Q)
        [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null || true
        printf '\033[?25h\033[?1049l' >&2
        trap - INT TERM
        return 130
        ;;
      ""|$'\n'|$'\r')
        break
        ;;
    esac
  done

  [[ -n "$old_stty" ]] && stty "$old_stty" 2>/dev/null || true
  printf '\033[?25h\033[?1049l' >&2
  trap - INT TERM

  local i
  for ((i = 0; i < ${#ids[@]}; i++)); do
    if [[ ${selected[$i]} -eq 1 ]]; then
      printf "%s\n" "${ids[$i]}"
    fi
  done
}
