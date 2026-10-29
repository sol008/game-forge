#!/usr/bin/env bash
# merge_gate.sh: merge a branch into the current branch only if it is clean and green.
#
#   merge_gate.sh [--check] <branch>
#
# 1. fetch <branch> from origin if there is an origin (skip with FORGE_NO_FETCH=1)
# 2. `git merge-tree --write-tree` pre-check: on conflicts, list them and exit 2 (nothing merged)
# 3. `git merge --no-ff`, then run the tests:
#      $FORGE_TEST_CMD, else `npm test` if package.json has a real test script,
#      else `bash tools/test/run.sh --quick` if present. No test command = refuse (exit 5);
#      set FORGE_TEST_CMD=true to merge untested on purpose.
#    FORGE_TEST_STALL=<sec> wraps the tests in watchdog.sh. Browser tests inside the test
#    command should still go through governor.sh.
# 4. tests fail -> reset to the pre-merge commit (exit 1). Never pushes, never force-pushes.
# --check: stop after the pre-check.
# Exit: 0 merged+green (or already merged), 1 tests failed (rolled back), 2 conflicts,
#       3 merge failed, 4 dirty tree / merge in progress, 5 no test command, 6 bad ref.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=_lib.sh
. "$HERE/_lib.sh"

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }
check_only=0
[ "${1:-}" = --check ] && { check_only=1; shift; }
case "${1:-}" in -h | --help) usage; exit 0 ;; "") usage >&2; exit 2 ;; esac
branch=$1

say() { printf 'merge_gate: %s\n' "$*"; }

git rev-parse --git-dir >/dev/null 2>&1 || forge_die "merge_gate: not in a git repo"
top=$(git rev-parse --show-toplevel)
cd "$top"
if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
  say "a merge is already in progress here; resolve or abort it first"; exit 4
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  say "working tree has uncommitted changes; commit or stash them first"; git status --short | head -20; exit 4
fi

# ---- 1. fetch ----------------------------------------------------------------------------
if [ "${FORGE_NO_FETCH:-0}" != 1 ] && git remote | grep -qx origin; then
  case "$branch" in origin/*) rb=${branch#origin/} ;; *) rb=$branch ;; esac
  git fetch --quiet origin "+refs/heads/$rb:refs/remotes/origin/$rb" 2>/dev/null ||
    say "note: fetch of origin/$rb failed or branch not on origin; using local refs"
fi

# pick the ref: local branch, unless origin's copy is strictly ahead of it
ref=""
loc=""; rem=""
git rev-parse -q --verify "refs/heads/$branch^{commit}" >/dev/null && loc="refs/heads/$branch"
git rev-parse -q --verify "refs/remotes/origin/$branch^{commit}" >/dev/null && rem="refs/remotes/origin/$branch"
if [ -n "$loc" ] && [ -n "$rem" ]; then
  if [ "$(git rev-parse "$loc")" != "$(git rev-parse "$rem")" ] && git merge-base --is-ancestor "$loc" "$rem"; then
    ref=$rem
  else
    ref=$loc
    git merge-base --is-ancestor "$rem" "$loc" || say "warning: local $branch and origin/$branch have diverged; using local"
  fi
elif [ -n "$loc" ]; then ref=$loc
elif [ -n "$rem" ]; then ref=$rem
elif git rev-parse -q --verify "$branch^{commit}" >/dev/null; then ref=$branch
else say "no such branch or ref: $branch"; exit 6; fi

pre=$(git rev-parse HEAD)
cur=$(git symbolic-ref --short -q HEAD || echo "detached@${pre:0:8}")
tip=$(git rev-parse "$ref")
if git merge-base --is-ancestor "$tip" HEAD; then
  say "PASS (nothing to do): $branch (${tip:0:8}) is already in $cur"; exit 0
fi
say "$branch -> $cur: $(git rev-list --count "HEAD..$tip") new commit(s), ref $ref"

# ---- 2. pre-check ------------------------------------------------------------------------
mrc=0
out=$(git merge-tree --write-tree --name-only HEAD "$tip" 2>&1) || mrc=$?
if [ "$mrc" = 0 ]; then
  say "pre-check: clean (merge-tree)"
elif [ "$mrc" = 1 ] && printf '%s' "$out" | head -n 1 | grep -Eq '^[0-9a-f]{40,64}$'; then
  say "CONFLICT: $branch does not merge cleanly into $cur. Nothing was merged. Conflicted files:"
  printf '%s\n' "$out" | sed -n '2,/^$/p' | sed '/^$/d; s/^/  /'
  printf '%s\n' "$out" | sed -n '/^$/,$p' | grep -i conflict | sed 's/^/  /' | head -20 || true
  exit 2
elif [ "$mrc" = 129 ]; then
  # git < 2.38 has no --write-tree: fall back to a trial merge that is always undone
  say "pre-check: merge-tree --write-tree unavailable (git $(git --version | awk '{print $3}')); trial merge"
  if ! tout=$(git merge --no-commit --no-ff "$tip" 2>&1); then
    files=$(git diff --name-only --diff-filter=U)
    git merge --abort 2>/dev/null || git reset -q --hard "$pre"
    if [ -n "$files" ]; then
      say "CONFLICT: $branch does not merge cleanly into $cur. Nothing was merged. Conflicted files:"
      printf '%s\n' "$files" | sed 's/^/  /'
      exit 2
    fi
    say "cannot merge $branch: $tout"; exit 3
  fi
  git merge --abort 2>/dev/null || git reset -q --hard "$pre"
else
  say "cannot merge $branch (merge-tree exit $mrc): $(printf '%s' "$out" | head -n 3)"; exit 3
fi
[ "$check_only" = 1 ] && { say "--check: stopping before merge"; exit 0; }

# ---- choose the test command before touching anything ------------------------------------
tcmd=${FORGE_TEST_CMD:-}
if [ -z "$tcmd" ] && [ -f package.json ]; then
  t=""
  if command -v jq >/dev/null 2>&1; then t=$(jq -r '.scripts.test // empty' package.json 2>/dev/null || true)
  elif command -v python3 >/dev/null 2>&1; then
    t=$(python3 -I -c 'import json;print(json.load(open("package.json")).get("scripts",{}).get("test",""))' 2>/dev/null || true)
  else t=$(grep -o '"test"[[:space:]]*:' package.json || true); fi
  case "$t" in "" | *"no test specified"*) ;; *) tcmd="npm test" ;; esac
fi
if [ -z "$tcmd" ] && [ -f tools/test/run.sh ]; then tcmd="bash tools/test/run.sh --quick"; fi
if [ -z "$tcmd" ]; then
  say "no test command (set FORGE_TEST_CMD; FORGE_TEST_CMD=true merges untested). Nothing merged."; exit 5
fi

# ---- 3. merge ----------------------------------------------------------------------------
if ! git merge --no-ff --no-edit -m "Merge $branch into $cur (merge_gate)" "$tip"; then
  say "merge failed unexpectedly; aborting"
  git merge --abort 2>/dev/null || git reset -q --hard "$pre"
  exit 3
fi
merged=$(git rev-parse HEAD)

FD=$(forge_dir)
mkdir -p "$FD/merge_gate"
tlog="$FD/merge_gate/$(printf '%s' "$branch" | tr -c 'A-Za-z0-9._-' '_').log"
say "tests: $tcmd  (log $tlog)"
: >"$tlog"
rc=0
if [ -n "${FORGE_TEST_STALL:-}" ]; then
  "$HERE/watchdog.sh" -q "$tlog" "$FORGE_TEST_STALL" -- bash -c "$tcmd" || rc=$?
else
  bash -c "$tcmd" >>"$tlog" 2>&1 || rc=$?
fi

# ---- 4. verdict --------------------------------------------------------------------------
if [ "$rc" != 0 ]; then
  say "tests FAILED (exit $rc). Last 30 lines:"
  tail -n 30 "$tlog" | sed 's/^/  | /'
  if [ "$(git rev-parse HEAD)" = "$merged" ] || git merge-base --is-ancestor "$merged" HEAD; then
    git reset -q --hard "$pre"
  else
    git merge --abort 2>/dev/null || git reset -q --hard "$pre"
  fi
  say "ROLLED BACK to ${pre:0:8}; $branch not merged. Send the log to the branch owner."
  exit 1
fi
say "PASS: merged $branch into $cur as ${merged:0:8}; tests green. Not pushed."
exit 0
