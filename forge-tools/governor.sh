#!/usr/bin/env bash
# governor.sh: lock-file semaphore for headless-browser (and other CPU-heavy) jobs.
#
#   governor.sh [--prio] [--max-hold SEC] [--] <cmd...>   run cmd when a slot is free
#   governor.sh --status [--brief]                        list holders and waiters
#   governor.sh --set-slots N | --set-slots auto          change the slot count live
#
# Slots: $FORGE_DIR/governor/slots file (live, set with --set-slots) > $FORGE_SLOTS > nproc-1; min 1.
#        Re-read on every poll, so waiters see a new slot at once.
# Order: --prio (user-reported bugs) first, then FIFO by arrival.
# Locks: mkdir-based (atomic, works on macOS without flock). A slot whose holder pid and child
#        pid are both dead is freed on the next poll by any waiter.
# Hold:  --max-hold SEC (default $FORGE_MAX_HOLD or 1800; 0 = unlimited). On expiry the job's
#        whole process group is killed, the kill is logged and the exit status is 124.
# Waits: a wait over $FORGE_QUEUE_WARN seconds (default 300) is logged to $FORGE_DIR/queue.log.
# Exit:  the command's own exit status; 124 on max-hold kill; 130/143 if the governor is
#        interrupted. The child sees FORGE_GOVERNOR_SLOT=<n>.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=_lib.sh
. "$HERE/_lib.sh"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }

FD=$(forge_dir)
G="$FD/governor"
mkdir -p "$G/slots" "$G/wait"
QLOG="$FD/queue.log"
POLL=${FORGE_POLL:-2}
WARN=${FORGE_QUEUE_WARN:-300}

qlog() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$QLOG"; }

slot_count() {
  local n=""
  [ -f "$G/slots.conf" ] && n=$(tr -dc '0-9' <"$G/slots.conf" 2>/dev/null || true)
  [ -z "$n" ] && n=${FORGE_SLOTS:-}
  case "$n" in '' | *[!0-9]*) n=$(($(forge_nproc) - 1)) ;; esac
  [ "$n" -lt 1 ] && n=1
  printf '%s\n' "$n"
}

slot_source() {
  if [ -f "$G/slots.conf" ]; then echo "slots.conf"
  elif [ -n "${FORGE_SLOTS:-}" ]; then echo "FORGE_SLOTS"
  else echo "nproc-1"; fi
}

clean_stale() {
  local d pid cpid t now cmd
  now=$(forge_now)
  for d in "$G"/slots/*; do
    [ -d "$d" ] || continue
    pid=$(cat "$d/pid" 2>/dev/null || true)
    if [ -z "$pid" ]; then
      # mkdir done but pid not yet written; only reap if it has been like that for 30 s
      [ $((now - $(forge_mtime "$d"))) -gt 30 ] && rm -rf "$d"
      continue
    fi
    forge_alive "$pid" && continue
    cpid=$(cat "$d/child" 2>/dev/null || true)
    forge_alive "$cpid" && continue
    cmd=$(cat "$d/cmd" 2>/dev/null || true)
    rm -rf "$d" && qlog "STALE slot ${d##*/} freed (pid $pid dead): $cmd"
  done
  for t in "$G"/wait/*; do
    [ -f "$t" ] || continue
    pid=$(sed -n 1p "$t" 2>/dev/null || true)
    forge_alive "$pid" || rm -f "$t"
  done
}

held_count() {
  local n=0 d
  for d in "$G"/slots/*; do [ -d "$d" ] && n=$((n + 1)); done
  printf '%s\n' "$n"
}

show_status() {
  local brief=$1 n held now d t i pid start prio cmd waiters=0 maxwait=0 w
  clean_stale
  n=$(slot_count); held=$(held_count); now=$(forge_now)
  for t in "$G"/wait/*; do
    [ -f "$t" ] || continue
    waiters=$((waiters + 1)); w=$((now - $(sed -n 2p "$t")))
    [ "$w" -gt "$maxwait" ] && maxwait=$w
  done
  if [ "$brief" = 1 ]; then
    printf 'held=%s slots=%s waiters=%s maxwait=%s\n' "$held" "$n" "$waiters" "$maxwait"
    return 0
  fi
  printf 'governor: %s/%s slots busy (%s), %s waiting; load %s on %s cores; dir %s\n' \
    "$held" "$n" "$(slot_source)" "$waiters" "$(forge_load1)" "$(forge_nproc)" "$G"
  printf 'HOLDERS\n'
  for d in "$G"/slots/*; do
    [ -d "$d" ] || continue
    pid=$(cat "$d/pid" 2>/dev/null || echo '?'); start=$(cat "$d/start" 2>/dev/null || echo "$now")
    prio=$(cat "$d/prio" 2>/dev/null || echo 0); cmd=$(cat "$d/cmd" 2>/dev/null || true)
    printf '  slot %-3s pid %-7s held %-7s %s%s\n' "${d##*/}" "$pid" "$(forge_age $((now - start)))" \
      "$([ "$prio" = 1 ] && echo '[prio] ')" "$cmd"
  done
  printf 'WAITERS (in grant order)\n'
  i=0
  for t in $(ls "$G/wait" 2>/dev/null | LC_ALL=C sort); do
    i=$((i + 1))
    pid=$(sed -n 1p "$G/wait/$t"); start=$(sed -n 2p "$G/wait/$t"); cmd=$(sed -n 3p "$G/wait/$t")
    w=$((now - start))
    printf '  #%-3s pid %-7s waiting %-7s %s%s%s\n' "$i" "$pid" "$(forge_age "$w")" \
      "$(case $t in (0-*) echo '[prio] ' ;; esac)" "$cmd" "$([ "$w" -ge "$WARN" ] && echo '   <-- over 5 min')"
  done
}

# ---- argument parsing --------------------------------------------------------------------
prio=0
max_hold=${FORGE_MAX_HOLD:-1800}
while [ $# -gt 0 ]; do
  case "$1" in
    --status) shift; show_status "$([ "${1:-}" = --brief ] && echo 1 || echo 0)"; exit 0 ;;
    --set-slots)
      [ $# -ge 2 ] || forge_die "--set-slots needs N or auto"
      if [ "$2" = auto ]; then rm -f "$G/slots.conf"; else
        case "$2" in '' | *[!0-9]*) forge_die "--set-slots: not a number: $2" ;; esac
        printf '%s\n' "$2" >"$G/slots.conf"
      fi
      qlog "SLOTS set to $2"; echo "slots now $(slot_count) ($(slot_source))"; exit 0 ;;
    --prio) prio=1; shift ;;
    --max-hold)
      [ $# -ge 2 ] || forge_die "--max-hold needs seconds"
      max_hold=$2; shift 2
      case "$max_hold" in '' | *[!0-9]*) forge_die "--max-hold: not a number: $max_hold" ;; esac ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    -*) forge_die "governor.sh: unknown option $1 (see --help)" ;;
    *) break ;;
  esac
done
[ $# -gt 0 ] || { usage >&2; exit 2; }

cmdstr=$(printf '%s ' "$@" | tr '\n' ' ' | head -c 200)
t0=$(forge_now)
ticket="$G/wait/$((1 - prio))-${t0}-$(printf '%07d' $$)"
printf '%s\n%s\n%s\n' "$$" "$t0" "$cmdstr" >"$G/.t.$$"
mv "$G/.t.$$" "$ticket"

slot=""
child=""
timer=""
cleanup() {
  if [ -n "$timer" ]; then kill "$timer" 2>/dev/null || true; fi
  rm -f "$ticket" "$G/.t.$$" || true
  if [ -n "$slot" ]; then rm -rf "$G/slots/$slot" || true; fi
  return 0
}
on_signal() {
  local code=$1
  if [ -n "$child" ]; then kill -TERM -- "-$child" 2>/dev/null || kill -TERM "$child" 2>/dev/null || true; fi
  exit "$code"
}
trap cleanup EXIT
trap 'on_signal 130' INT
trap 'on_signal 143' TERM
trap 'on_signal 129' HUP

# ---- wait for a slot ---------------------------------------------------------------------
warned=0
while :; do
  clean_stale
  n=$(slot_count)
  free=$((n - $(held_count)))
  if [ "$free" -gt 0 ]; then
    rank=$(ls "$G/wait" | LC_ALL=C sort | grep -n -x -F "${ticket##*/}" | cut -d: -f1 || true)
    if [ -z "$rank" ]; then # ticket lost (e.g. dir wiped): re-file it
      printf '%s\n%s\n%s\n' "$$" "$t0" "$cmdstr" >"$ticket"; rank=1
    fi
    if [ $((rank - 1)) -lt "$free" ]; then
      i=1
      while [ "$i" -le "$n" ]; do
        if mkdir "$G/slots/$i" 2>/dev/null; then
          slot=$i
          printf '%s\n' "$$" >"$G/slots/$i/pid"
          forge_now >"$G/slots/$i/start"
          printf '%s\n' "$prio" >"$G/slots/$i/prio"
          printf '%s\n' "$cmdstr" >"$G/slots/$i/cmd"
          break
        fi
        i=$((i + 1))
      done
      [ -n "$slot" ] && break
    fi
  fi
  waited=$(($(forge_now) - t0))
  if [ "$warned" = 0 ] && [ "$waited" -ge "$WARN" ]; then
    warned=1
    qlog "WAIT>${WARN}s pid $$ $([ "$prio" = 1 ] && echo '[prio] ')still queued ($(held_count)/$n busy): $cmdstr"
    printf 'governor: waiting %ss for a slot (%s/%s busy); see governor.sh --status\n' "$waited" "$(held_count)" "$n" >&2
  fi
  sleep "$POLL"
done
rm -f "$ticket"
waited=$(($(forge_now) - t0))
[ "$waited" -ge "$WARN" ] && qlog "GRANT slot $slot after ${waited}s pid $$: $cmdstr"

# ---- run, in its own process group so a kill takes the whole tree (e.g. node + chromium) --
export FORGE_GOVERNOR_SLOT=$slot
start=$(forge_now)
set -m
"$@" &
child=$!
set +m
printf '%s\n' "$child" >"$G/slots/$slot/child"

marker="$G/slots/$slot/maxhold"
if [ "$max_hold" -gt 0 ]; then
  (
    trap - EXIT INT TERM HUP
    end=$((start + max_hold))
    while kill -0 "$child" 2>/dev/null; do
      if [ "$(forge_now)" -ge "$end" ]; then
        : >"$marker"
        kill -TERM -- "-$child" 2>/dev/null || kill -TERM "$child" 2>/dev/null || true
        k=0
        while kill -0 "$child" 2>/dev/null && [ "$k" -lt 10 ]; do sleep 0.5; k=$((k + 1)); done
        kill -KILL -- "-$child" 2>/dev/null || true
        exit 0
      fi
      sleep 1
    done
  ) &
  timer=$!
fi

rc=0
wait "$child" 2>/dev/null || rc=$?
if [ -f "$marker" ]; then
  held=$(($(forge_now) - start))
  qlog "MAXHOLD killed after ${held}s (limit ${max_hold}s) slot $slot pid $child: $cmdstr"
  printf 'governor: KILLED after %ss: job exceeded --max-hold %ss (slot %s): %s\n' "$held" "$max_hold" "$slot" "$cmdstr" >&2
  exit 124
fi
exit "$rc"
