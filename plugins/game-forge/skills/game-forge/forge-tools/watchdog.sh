#!/usr/bin/env bash
# watchdog.sh: run a command and kill it if its log stops growing.
#
#   watchdog.sh [-q] <logfile> [sec] -- <cmd...>
#
# The command's stdout+stderr are appended to <logfile> (it may also write there itself).
# If the log has not grown for <sec> seconds (default 90), the command's whole process group
# is killed (TERM, then KILL after 5 s), the last 20 log lines are printed to stderr, a line
# is added to $FORGE_DIR/watchdog.log, and the exit status is 125.
# Otherwise the command's exit status is returned and the last 20 lines are printed
# (-q: only on failure). Compose with the governor:
#   governor.sh watchdog.sh test.log 90 -- node tools/test/e2e.js
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=_lib.sh
. "$HERE/_lib.sh"

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; }
quiet=0
[ "${1:-}" = -q ] && { quiet=1; shift; }
case "${1:-}" in -h | --help) usage; exit 0 ;; esac
[ $# -ge 3 ] || { usage >&2; exit 2; }
log=$1; shift
sec=90
if [ "$1" != "--" ]; then sec=$1; shift; fi
case "$sec" in '' | *[!0-9]*) forge_die "watchdog.sh: seconds must be a number: $sec" ;; esac
[ "${1:-}" = "--" ] || forge_die "watchdog.sh: expected -- before the command"
shift
[ $# -gt 0 ] || forge_die "watchdog.sh: no command"

mkdir -p "$(dirname "$log")"
touch "$log"
log="$(cd "$(dirname "$log")" && pwd)/$(basename "$log")"
cmdstr=$(printf '%s ' "$@" | head -c 200)

child=""
on_signal() {
  [ -n "$child" ] && { kill -TERM -- "-$child" 2>/dev/null || kill -TERM "$child" 2>/dev/null || true; }
  exit "$1"
}
trap 'on_signal 130' INT
trap 'on_signal 143' TERM
trap 'on_signal 129' HUP

set -m
"$@" >>"$log" 2>&1 &
child=$!
set +m

last_size=$(forge_size "$log")
last_change=$(forge_now)
stalled=0
while kill -0 "$child" 2>/dev/null; do
  sleep 1
  s=$(forge_size "$log")
  now=$(forge_now)
  if [ "$s" != "$last_size" ]; then
    last_size=$s; last_change=$now
  elif [ $((now - last_change)) -ge "$sec" ]; then
    stalled=1
    kill -TERM -- "-$child" 2>/dev/null || kill -TERM "$child" 2>/dev/null || true
    k=0
    while kill -0 "$child" 2>/dev/null && [ "$k" -lt 10 ]; do sleep 0.5; k=$((k + 1)); done
    kill -KILL -- "-$child" 2>/dev/null || true
    break
  fi
done
rc=0
wait "$child" 2>/dev/null || rc=$?

if [ "$stalled" = 1 ]; then
  msg="WATCHDOG: no log growth for ${sec}s; killed pid $child: $cmdstr"
  {
    printf '\n%s\n' "$msg"
    printf -- '--- last 20 lines of %s ---\n' "$log"
    tail -n 20 "$log"
  } >&2
  printf '[watchdog %s] %s\n' "$(date '+%H:%M:%S')" "$msg" >>"$log"
  FD=$(forge_dir 2>/dev/null || true)
  [ -n "$FD" ] && printf '%s %s (log %s)\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$msg" "$log" >>"$FD/watchdog.log"
  exit 125
fi
if [ "$quiet" = 0 ] || [ "$rc" != 0 ]; then
  printf -- '--- last 20 lines of %s (exit %s) ---\n' "$log" "$rc"
  tail -n 20 "$log"
fi
exit "$rc"
