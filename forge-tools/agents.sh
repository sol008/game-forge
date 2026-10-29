#!/usr/bin/env bash
# agents.sh: agent registry over $FORGE_DIR/agents.json (the lead's memory across compaction).
#
#   agents.sh add  <id> <task> <branch> <log> [eta]   register a launch (status=running)
#   agents.sh set  <id> status|eta|note|task|branch|log <value>
#   agents.sh set  <id> worktree <path>                optional: the agent's git worktree
#   agents.sh set  <id> chapter <n>                    optional: chapter number (or range N-M)
#   agents.sh done <id> [status] [note]                mark finished (default status=done); status
#                                                      must be terminal, e.g. `done ch3 stopped drained`
#   agents.sh list                                     human-readable table
#   agents.sh get  <id>                                one entry as JSON
#   agents.sh tsv                                      machine form (used by status.sh)
#   agents.sh rm   <id>                                forget an entry
#
# eta: "+20m", "+2h", "HH:MM" (converted to an absolute time) or any free text.
# branch/log: use "-" when there is none (e.g. a cloud session has a branch but no local log).
# Terminal statuses (not stall-checked): done failed stopped merged cancelled.
# A drained agent is `stopped` with note "drained" ("drained" is not a status).
# Uses jq if present, otherwise python3 (force with FORGE_JSON=python).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=_lib.sh
. "$HERE/_lib.sh"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }
TERMINAL="done failed stopped merged cancelled"
is_terminal() { case " $TERMINAL " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

FD=$(forge_dir)
DB="$FD/agents.json"
LOCK="$FD/.agents.lock"
[ -s "$DB" ] || printf '{}\n' >"$DB"

ENGINE=${FORGE_JSON:-}
if [ -z "$ENGINE" ]; then
  if command -v jq >/dev/null 2>&1; then ENGINE=jq
  elif command -v python3 >/dev/null 2>&1; then ENGINE=python
  else forge_die "agents.sh needs jq or python3"; fi
fi

lock() {
  local i=0
  until mkdir "$LOCK" 2>/dev/null; do
    i=$((i + 1))
    # a lock older than 30 s belongs to a crashed writer
    if [ $(($(forge_now) - $(forge_mtime "$LOCK"))) -gt 30 ]; then rm -rf "$LOCK"; continue; fi
    [ "$i" -gt 300 ] && forge_die "agents.sh: registry lock busy: $LOCK"
    sleep 0.1
  done
  trap 'rm -rf "$LOCK"' EXIT
}

clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }

# eta text -> epoch (or "null")
eta_epoch() {
  local e=$1 now n h m s mid t
  now=$(forge_now)
  case "$e" in
    +*[mh])
      n=${e#+}; n=${n%?}
      case "$n" in '' | *[!0-9]*) echo null; return ;; esac
      case "$e" in *m) echo $((now + n * 60)) ;; *h) echo $((now + n * 3600)) ;; esac ;;
    [0-9]:[0-5][0-9] | [0-2][0-9]:[0-5][0-9])
      h=$((10#${e%%:*})); m=$((10#${e##*:}))
      mid=$((now - 10#$(date +%H) * 3600 - 10#$(date +%M) * 60 - 10#$(date +%S)))
      t=$((mid + h * 3600 + m * 60))
      [ "$t" -lt $((now - 6 * 3600)) ] && t=$((t + 86400))
      echo "$t" ;;
    *) echo null ;;
  esac
}

eta_text() { # relative etas are stored as absolute HH:MM so they don't go stale
  local e=$1 ep=$2
  case "$e" in +*) [ "$ep" != null ] && { forge_hhmm "$ep"; return; } ;; esac
  printf '%s\n' "$e"
}

# write: run the update (jq filter or python op) and atomically replace the db
apply() { # apply <op> <id> [args...]
  local op=$1 id=$2 tmp
  shift 2
  tmp="$DB.tmp.$$"
  if [ "$ENGINE" = jq ]; then
    local now
    now=$(forge_now)
    case "$op" in
      add)
        jq --arg id "$id" --arg task "$1" --arg branch "$2" --arg log "$3" --arg eta "$4" \
          --argjson ep "$5" --argjson now "$now" \
          '.[$id] = {id:$id, task:$task, branch:$branch, log:$log, eta:$eta, eta_epoch:$ep,
                     status:"running", note:"", started:$now, updated:$now, ended:null}' "$DB" >"$tmp" ;;
      set)
        jq --arg id "$id" --arg f "$1" --arg v "$2" --argjson ep "$3" --argjson now "$now" \
          '.[$id][$f] = $v | .[$id].updated = $now
           | if $f == "eta" then .[$id].eta_epoch = $ep else . end
           | if $f == "status" then
               (if ($v|IN("done","failed","stopped","merged","cancelled")) then .[$id].ended = $now
                else .[$id].ended = null end)
             else . end' "$DB" >"$tmp" ;;
      rm) jq --arg id "$id" 'del(.[$id])' "$DB" >"$tmp" ;;
    esac
  else
    python3 -I - "$DB" "$tmp" "$op" "$id" "$@" <<'PY'
import json, sys, time
db, tmp, op, aid, *a = sys.argv[1:]
with open(db, encoding="utf-8") as f: d = json.load(f)
now = int(time.time())
num = lambda s: None if s == "null" else int(s)
if op == "add":
    d[aid] = dict(id=aid, task=a[0], branch=a[1], log=a[2], eta=a[3], eta_epoch=num(a[4]),
                  status="running", note="", started=now, updated=now, ended=None)
elif op == "set":
    e = d[aid]; e[a[0]] = a[1]; e["updated"] = now
    if a[0] == "eta": e["eta_epoch"] = num(a[2])
    if a[0] == "status":
        e["ended"] = now if a[1] in ("done", "failed", "stopped", "merged", "cancelled") else None
elif op == "rm":
    d.pop(aid, None)
with open(tmp, "w", encoding="utf-8") as f: json.dump(d, f, ensure_ascii=False, indent=1); f.write("\n")
PY
  fi
  mv "$tmp" "$DB"
}

has() {
  if [ "$ENGINE" = jq ]; then jq -e --arg id "$1" 'has($id)' "$DB" >/dev/null
  else python3 -I -c 'import json,sys; sys.exit(0 if sys.argv[2] in json.load(open(sys.argv[1],encoding="utf-8")) else 1)' "$DB" "$1"; fi
}

tsv() { # id task status eta eta_epoch branch log started updated note worktree chapter
        # (sorted by start time; new columns go at the end so readers can ignore them)
  if [ "$ENGINE" = jq ]; then
    jq -r 'to_entries | sort_by(.value.started) | .[].value
      | [.id, .task, .status, .eta, (.eta_epoch // "null"), .branch, .log, .started, .updated, .note,
         (.worktree // "-"), (.chapter // "-")]
      | map(tostring | if . == "" then "-" else . end) | @tsv' "$DB"
  else
    python3 -I -c '
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
for e in sorted(d.values(), key=lambda e: e.get("started", 0)):
    f = [e.get(k) for k in ("id","task","status","eta","eta_epoch","branch","log","started","updated","note")]
    f += [e.get("worktree") or "-", e.get("chapter") or "-"]
    print("\t".join("null" if v is None else (str(v) or "-") for v in f))' "$DB"
  fi
}

cmd=${1:-}
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift
case "$cmd" in
  add)
    [ $# -ge 4 ] || forge_die "usage: agents.sh add <id> <task> <branch> <log> [eta]"
    id=$(clean "$1"); eta=$(clean "${5:--}"); ep=$(eta_epoch "$eta"); eta=$(eta_text "$eta" "$ep")
    lock
    if has "$id"; then echo "agents.sh: re-registering existing id $id" >&2; fi
    apply add "$id" "$(clean "$2")" "$(clean "$3")" "$(clean "$4")" "$eta" "$ep"
    echo "registered $id" ;;
  set)
    [ $# -ge 3 ] || forge_die "usage: agents.sh set <id> status|eta|note|task|branch|log|worktree|chapter <value>"
    id=$1; field=$2; val=$(clean "$3"); ep=null
    case "$field" in
      note | task | branch | log) ;;
      status)
        [ "$val" = drained ] && forge_die "agents.sh: 'drained' is not a status; use: agents.sh done $id stopped drained" ;;
      eta) ep=$(eta_epoch "$val"); val=$(eta_text "$val" "$ep") ;;
      worktree) [ -d "$val" ] && val=$(cd "$val" && pwd) ;;
      chapter)
        case "$val" in
          '' | *[!0-9-]* | -* | *- | *-*-*) forge_die "agents.sh: chapter wants N or N-M, got '$val'" ;;
        esac ;;
      *) forge_die "agents.sh: unknown field '$field' (status|eta|note|task|branch|log|worktree|chapter)" ;;
    esac
    lock
    has "$id" || forge_die "agents.sh: no agent '$id' (see agents.sh list)"
    apply set "$id" "$field" "$val" "$ep"
    echo "$id.$field = $val" ;;
  done)
    [ $# -ge 1 ] || forge_die "usage: agents.sh done <id> [status] [note]"
    st=$(clean "${2:-done}")
    if ! is_terminal "$st"; then
      hint=""; [ "$st" = drained ] && hint="; use: agents.sh done $1 stopped drained"
      forge_die "agents.sh: done wants a terminal status ($TERMINAL), got '$st'$hint"
    fi
    lock
    has "$1" || forge_die "agents.sh: no agent '$1'"
    apply set "$1" status "$st" null
    [ $# -ge 3 ] && apply set "$1" note "$(clean "$3")" null
    echo "$1 -> $st${3:+ ($3)}" ;;
  rm)
    [ $# -ge 1 ] || forge_die "usage: agents.sh rm <id>"
    lock; apply rm "$1"; echo "removed $1" ;;
  get)
    [ $# -ge 1 ] || forge_die "usage: agents.sh get <id>"
    has "$1" || forge_die "agents.sh: no agent '$1'"
    if [ "$ENGINE" = jq ]; then jq --arg id "$1" '.[$id]' "$DB"
    else python3 -I -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1],encoding="utf-8"))[sys.argv[2]], ensure_ascii=False, indent=1))' "$DB" "$1"; fi ;;
  tsv) tsv ;;
  list)
    now=$(forge_now)
    { printf 'ID\tSTATUS\tETA\tAGE\tCH\tBRANCH\tWORKTREE\tTASK\tNOTE\n'
      tsv | while IFS="$(printf '\t')" read -r id task st eta ep br _lg started _upd note wt ch; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$st" "$eta" "$(forge_age $((now - started)))" "$ch" "$br" "$wt" "$task" "$note"
      done; } | if command -v column >/dev/null 2>&1; then column -t -s "$(printf '\t')"; else cat; fi ;;
  -h | --help | help) usage ;;
  *) forge_die "agents.sh: unknown command '$cmd' (see --help)" ;;
esac
