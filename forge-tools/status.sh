#!/usr/bin/env bash
# status.sh: ONE markdown table for the 15-min check-in.
#
#   status.sh [--if-changed]
#
# Header line: time, CPU load vs cores, governor queue, spend (if $FORGE_DIR/spend.txt exists;
# cap from $FORGE_DIR/budget.txt or $FORGE_BUDGET, warns at 70% / 90%).
# Table: agent | task | status | ETA | last log line (age) | branch | last commit.
# Stall: an active agent whose log has not grown and whose branch has had no commit for
#        $FORGE_STALL_MIN minutes (default 20) is flagged STALLED. Exit status 3 if any.
# --if-changed: print nothing when nothing but ages changed since the last run (stalls always
#        print). Lets the check-in loop stay silent on no-op checks.
# Git info is read from $FORGE_REPO (default: current dir). No network: run `git fetch` first
# if cloud branches should be fresh.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=_lib.sh
. "$HERE/_lib.sh"

if_changed=0
case "${1:-}" in
  --if-changed) if_changed=1 ;;
  -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) forge_die "status.sh: unknown option $1" ;;
esac

FD=$(forge_dir)
REPO=${FORGE_REPO:-.}
STALL_MIN=${FORGE_STALL_MIN:-20}
STALL_S=$((STALL_MIN * 60))
now=$(forge_now)
TAB=$(printf '\t')
git_ok=0
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 && git_ok=1

# ---- header ------------------------------------------------------------------------------
cores=$(forge_nproc)
load=$(forge_load1)
load_flag=$(awk -v l="$load" -v c="$cores" 'BEGIN{ if (l > c) print "HIGH"; else if (l < c - 1.5) print "spare"; else print "ok" }')
gov=$("$HERE/governor.sh" --status --brief 2>/dev/null || echo "held=? slots=? waiters=0 maxwait=0")
g_held=$(printf '%s' "$gov" | sed 's/.*held=\([^ ]*\).*/\1/')
g_slots=$(printf '%s' "$gov" | sed 's/.*slots=\([^ ]*\).*/\1/')
g_wait=$(printf '%s' "$gov" | sed 's/.*waiters=\([^ ]*\).*/\1/')
g_max=$(printf '%s' "$gov" | sed 's/.*maxwait=\([^ ]*\).*/\1/')
queue="governor ${g_held}/${g_slots} busy, ${g_wait} waiting"
if [ "$g_wait" != 0 ] && [ "$g_max" != "?" ]; then
  queue="$queue (longest $(forge_age "$g_max"))"
  [ "$g_max" -ge "${FORGE_QUEUE_WARN:-300}" ] && queue="$queue **QUEUE >5m**"
fi

spend=""
if [ -f "$FD/spend.txt" ]; then
  last=$(grep -v '^[[:space:]]*\(#\|$\)' "$FD/spend.txt" | tail -n 1 || true)
  amt=$(printf '%s' "$last" | grep -o '\$[0-9][0-9.,]*' | head -n 1 | tr -d '$,' || true)
  cap=${FORGE_BUDGET:-}
  [ -z "$cap" ] && [ -f "$FD/budget.txt" ] && cap=$(grep -o '[0-9][0-9.]*' "$FD/budget.txt" | head -n 1 || true)
  if [ -n "$amt" ]; then
    spend=" · spend \$$amt"
    if [ -n "$cap" ]; then
      spend="$spend $(awk -v a="$amt" -v c="$cap" 'BEGIN{ p = (c > 0) ? 100 * a / c : 0;
        s = sprintf("(%d%% of $%s cap)", p, c);
        if (p >= 90) s = s " **CHECKPOINT: >=90%, go serial**"; else if (p >= 70) s = s " **WARN >=70%**";
        print s }')"
    else spend="$spend (no cap)"; fi
  else
    spend=" · spend: $(forge_oneline "$last" 40)"
  fi
fi

# ---- rows --------------------------------------------------------------------------------
rows=""
sig=""
stalled=""
nact=0
while IFS="$TAB" read -r id task st eta ep br lg started _upd note; do
  [ -n "$id" ] || continue
  active=1
  case "$st" in done | failed | stopped | merged | cancelled) active=0 ;; esac
  # log
  log_cell="-"; log_age=""; lastline=""
  if [ "$lg" != "-" ] && [ -f "$lg" ]; then
    log_age=$((now - $(forge_mtime "$lg")))
    lastline=$(tail -c 4096 "$lg" | tr '\r' '\n' | grep -v '^[[:space:]]*$' | tail -n 1 || true)
    log_cell="\`$(forge_oneline "$lastline" 60)\` ($(forge_age "$log_age"))"
  elif [ "$lg" != "-" ]; then
    log_cell="(no log yet)"
  fi
  # branch + commit
  br_cell="-"; c_cell="-"; c_age=""; sha=""
  if [ "$git_ok" = 1 ] && [ "$br" != "-" ]; then
    ref=""
    for r in "$br" "origin/$br"; do
      if git -C "$REPO" rev-parse -q --verify "$r^{commit}" >/dev/null 2>&1; then ref=$r; break; fi
    done
    if [ -n "$ref" ]; then
      sha=$(git -C "$REPO" rev-parse --short "$ref")
      ct=$(git -C "$REPO" log -1 --format=%ct "$ref")
      c_age=$((now - ct))
      ahead=$(git -C "$REPO" rev-list --count "HEAD..$ref" 2>/dev/null || echo "?")
      br_cell="$br (+$ahead)"
      c_cell="$(forge_age "$c_age") ago"
    else
      br_cell="$br (missing)"
    fi
  elif [ "$br" != "-" ]; then
    br_cell=$br
  fi
  # stall: the freshest sign of life among log growth and commits; with neither, launch time
  st_cell=$st; is_st=""
  if [ "$active" = 1 ]; then
    nact=$((nact + 1))
    life=""
    [ -n "$log_age" ] && life=$log_age
    if [ -n "$c_age" ]; then { [ -z "$life" ] || [ "$c_age" -lt "$life" ]; } && life=$c_age; fi
    [ -z "$life" ] && life=$((now - started))
    if [ "$life" -ge "$STALL_S" ]; then
      st_cell="**STALLED $(forge_age "$life")** ($st)"
      stalled="$stalled $id"; is_st=S
    fi
  fi
  eta_cell=$eta
  if [ "$active" = 1 ] && [ "$ep" != null ] && [ "$ep" -lt "$now" ]; then
    eta_cell="$eta (overdue $(forge_age $((now - ep))))"
  fi
  [ "$note" != "-" ] && st_cell="$st_cell: $(forge_oneline "$note" 40)"
  rows="$rows| $(forge_oneline "$id" 30) | $(forge_oneline "$task" 40) | $st_cell | $eta_cell | $log_cell | $br_cell | $c_cell |
"
  sig="$sig$id|$st|$eta|$note|$sha|$lastline|$is_st
"
done <<EOF
$("$HERE/agents.sh" tsv)
EOF

sig="$sig$g_held/$g_slots/$g_wait"
if [ "$if_changed" = 1 ]; then
  hash=$(printf '%s' "$sig" | cksum | cut -d' ' -f1)
  prev=$(cat "$FD/status.sig" 2>/dev/null || true)
  printf '%s\n' "$hash" >"$FD/status.sig"
  if [ "$hash" = "$prev" ] && [ -z "$stalled" ]; then exit 0; fi
fi

printf '**Forge status %s** · load %s / %s cores (%s) · %s%s · %s active\n\n' \
  "$(date +%H:%M)" "$load" "$cores" "$load_flag" "$queue" "$spend" "$nact"
printf '| agent | task | status | ETA | last log line (age) | branch | last commit |\n'
printf '|---|---|---|---|---|---|---|\n'
if [ -n "$rows" ]; then printf '%s' "$rows"; else printf '| (no agents registered) | | | | | | |\n'; fi
if [ -n "$stalled" ]; then
  printf '\nSTALLED (no log growth or commits for %sm):%s\n' "$STALL_MIN" "$stalled"
  exit 3
fi
exit 0
