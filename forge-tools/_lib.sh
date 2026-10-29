# shellcheck shell=bash
# Shared helpers for forge-tools. Sourced, not executed. Portable to Linux and macOS (bash 3.2+).

# Resolve the forge state dir and make sure it exists and is git-ignored.
# FORGE_DIR wins. Otherwise: inside a git repo, the MAIN checkout's .forge (so every worktree
# shares one governor, registry and queue log); outside git, $PWD/.forge.
forge_dir() {
  local d="${FORGE_DIR:-}"
  if [ -z "$d" ]; then
    local common
    common=$(git rev-parse --git-common-dir 2>/dev/null || true)
    if [ -n "$common" ] && [ -d "$common" ]; then
      common=$(cd "$common" && pwd)
      case "$common" in
        */.git) d="${common%/.git}/.forge" ;;
        *) d="$PWD/.forge" ;;
      esac
    else
      d="$PWD/.forge"
    fi
  fi
  mkdir -p "$d"
  [ -f "$d/.gitignore" ] || printf '*\n' >"$d/.gitignore"
  printf '%s\n' "$d"
}

forge_now() { date +%s; }

forge_nproc() {
  local n
  n=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1)
  case "$n" in '' | *[!0-9]*) n=1 ;; esac
  printf '%s\n' "$n"
}

# 1-minute load average as a decimal string.
forge_load1() {
  if [ -r /proc/loadavg ]; then
    cut -d' ' -f1 /proc/loadavg
  elif sysctl -n vm.loadavg >/dev/null 2>&1; then
    sysctl -n vm.loadavg | tr -d '{}' | awk '{print $1}'
  else
    uptime | sed 's/.*load average[s]*: *//' | tr ',' ' ' | awk '{print $1}'
  fi
}

# Is this pid alive? (ps works across users, unlike kill -0)
forge_alive() {
  [ -n "${1:-}" ] || return 1
  ps -p "$1" >/dev/null 2>&1
}

forge_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }

forge_size() { if [ -f "$1" ]; then wc -c <"$1" | tr -d ' '; else echo 0; fi; }

# Seconds -> compact age: 42s, 12m, 3h05m, 2d04h
forge_age() {
  local s=${1:-0}
  [ "$s" -lt 0 ] && s=0
  if [ "$s" -lt 60 ]; then printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '%dm' $((s / 60))
  elif [ "$s" -lt 86400 ]; then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  else printf '%dd%02dh' $((s / 86400)) $((s % 86400 / 3600)); fi
}

# Epoch -> local HH:MM
forge_hhmm() { date -d "@$1" +%H:%M 2>/dev/null || date -r "$1" +%H:%M 2>/dev/null || echo "?"; }

# One-line, table-safe text: strip ANSI, keep the text after the last CR, escape pipes,
# truncate to $2 bytes without splitting a UTF-8 character.
forge_oneline() {
  local max=${2:-60} esc
  esc=$(printf '\033')
  printf '%s' "$1" | tr '\r' '\n' | tail -n 1 | sed "s/${esc}\[[0-9;?]*[A-Za-z]//g" | tr '\t`' " '" |
    sed 's/|/\\|/g' | head -c "$max" | { iconv -c -f UTF-8 -t UTF-8 2>/dev/null || cat; }
}

forge_die() { printf '%s\n' "$*" >&2; exit 2; }
